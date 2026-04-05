#!/bin/bash
# 在 Jetson Orin (SM 8.7, CUDA 12.6) 上编译 vLLM 0.19.0
# 基于 torch 2.10.0 (Jetson 官方源)，原生适配，无需 override
#
# 用法:
#   bash build_vllm.sh
#   nohup bash build_vllm.sh > build_vllm.log 2>&1 &
#
# 可配置环境变量:
#   BUILD_DIR    构建根目录，需要 ~20GB 空间（默认: /data）
#   OUTPUT_DIR   wheel 输出目录（默认: ./dist）
#   MAX_JOBS     并行编译数，建议 CPU核数-1（默认: 9）
#   PYPI_MIRROR  PyPI 镜像地址，海外用户留空即可（默认: 清华源）

set -e

# ============================================================
# 可配置变量
# ============================================================
BUILD_DIR="${BUILD_DIR:-/data}"
OUTPUT_DIR="${OUTPUT_DIR:-./dist}"
MAX_JOBS="${MAX_JOBS:-9}"
PYPI_MIRROR="${PYPI_MIRROR:-https://pypi.tuna.tsinghua.edu.cn/simple}"

SRC="$BUILD_DIR/vllm-src"
DEPS="$SRC/.deps"
VENV="$BUILD_DIR/vllm-build"

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# 把临时文件/缓存放到构建目录，避免根分区撑满
export PIP_CACHE_DIR="$BUILD_DIR/.pip-cache"
export TMPDIR="$BUILD_DIR/tmp"
mkdir -p "$PIP_CACHE_DIR" "$TMPDIR" "$OUTPUT_DIR"

log "===== vLLM 0.19.0 Jetson Orin 编译开始 (torch 2.10.0) ====="
log "BUILD_DIR:  $BUILD_DIR"
log "OUTPUT_DIR: $OUTPUT_DIR"
log "Python: $(python3 --version)"
log "CUDA:   $(nvcc --version | grep release)"
log "内存:   $(free -h | awk '/^Mem/{print $4}') 可用"

# PyPI 镜像参数
PIP_MIRROR_ARGS=""
if [ -n "$PYPI_MIRROR" ]; then
    MIRROR_HOST=$(echo "$PYPI_MIRROR" | sed 's|https\?://\([^/]*\).*|\1|')
    PIP_MIRROR_ARGS="-i $PYPI_MIRROR --trusted-host $MIRROR_HOST"
fi

# ============================================================
# 1. 预下载所有 cmake FetchContent 依赖（避免编译时断网失败）
# ============================================================
log "[1/6] 预下载 cmake 依赖仓库 ..."
mkdir -p "$DEPS"

clone_if_missing() {
    local name=$1 url=$2 ref=$3 dir="$DEPS/$name-src"
    if [ -d "$dir" ]; then
        log "  $name 已存在，跳过"
        return
    fi
    log "  克隆 $name ($ref) ..."
    if git clone --depth 1 -b "$ref" "$url" "$dir" 2>/dev/null; then
        return
    fi
    # tag 克隆失败则全量克隆后 checkout（用于 commit hash）
    git clone "$url" "$dir"
    cd "$dir" && git checkout "$ref" && cd -
}

clone_if_missing "cutlass"          "https://github.com/nvidia/cutlass.git"                "v4.2.1"
clone_if_missing "triton_kernels"   "https://github.com/triton-lang/triton.git"            "v3.6.0"
clone_if_missing "vllm_flash_attn"  "https://github.com/vllm-project/flash-attention.git"  "29210221863736a08f71a866459e368ad1ac4a95"
clone_if_missing "flashmla"         "https://github.com/vllm-project/FlashMLA"             "692917b1cda61b93ac9ee2d846ec54e75afe87b1"
clone_if_missing "qutlass"          "https://github.com/IST-DASLab/qutlass.git"            "830d2c4537c7396e14a02a46fbddd18b5d107c65"

log "  所有依赖下载完成"

# ============================================================
# 2. 创建独立虚拟环境，安装 Jetson 源的 torch 2.10.0
# ============================================================
log "[2/6] 创建独立虚拟环境 $VENV ..."
if [ -d "$VENV" ]; then
    log "  清理旧的构建环境 ..."
    rm -rf "$VENV"
fi
python3 -m venv "$VENV"
source "$VENV/bin/activate"
pip install -q --upgrade pip

log "  安装 torch 2.10.0 + torchvision 0.25.0 (Jetson 官方源) ..."
pip install \
    torch==2.10.0 \
    torchvision==0.25.0 \
    --index-url https://pypi.jetson-ai-lab.io/jp6/cu126

python3 - <<'PYEOF'
import torch
print(f"torch={torch.__version__}, cuda={torch.cuda.is_available()}, arch={torch.cuda.get_arch_list()}")
PYEOF

# ============================================================
# 3. 安装 Python 构建依赖
# ============================================================
log "[3/6] 安装 transformers + 构建依赖 ..."
pip install -q $PIP_MIRROR_ARGS \
    "transformers>=5.5.0" mistral_common \
    "setuptools>=61,<82" setuptools_scm wheel "packaging>=24.2" "cmake>=3.26" ninja

# ============================================================
# 4. 克隆 vLLM 0.19.0 源码
# ============================================================
log "[4/6] 检查 vLLM 源码 ..."
if [ -d "$SRC/.git" ]; then
    log "  源码目录已存在，跳过克隆"
else
    git clone --depth 1 --branch v0.19.0 \
        https://github.com/vllm-project/vllm.git "$SRC"
fi

cd "$SRC"

log "  配置 FetchContent 使用本地源码 ..."
export FETCHCONTENT_SOURCE_DIR_CUTLASS="$DEPS/cutlass-src"
export FETCHCONTENT_SOURCE_DIR_TRITON_KERNELS="$DEPS/triton_kernels-src"
export FETCHCONTENT_SOURCE_DIR_VLLM_FLASH_ATTN="$DEPS/vllm_flash_attn-src"
export FETCHCONTENT_SOURCE_DIR_FLASHMLA="$DEPS/flashmla-src"
export FETCHCONTENT_SOURCE_DIR_QUTLASS="$DEPS/qutlass-src"

# ============================================================
# 5. 编译
# ============================================================
log "[5/6] 开始编译 (SM 8.7, MAX_JOBS=$MAX_JOBS) ..."
log "  预计耗时 60-90 分钟，请耐心等待..."

export TORCH_CUDA_ARCH_LIST="8.7"
export MAX_JOBS
export VLLM_TARGET_DEVICE=cuda
export CUDA_HOME=/usr/local/cuda

pip install --no-build-isolation $PIP_MIRROR_ARGS .

# ============================================================
# 6. 打包 wheel
# ============================================================
log "[6/6] 打包 wheel ..."
pip wheel --no-build-isolation --no-deps -w "$OUTPUT_DIR" .

log "===== 编译完成！====="
log "wheel 文件:"
ls -lh "$OUTPUT_DIR"/vllm*.whl

python3 - <<'PYEOF'
import torch, vllm
print(f"vLLM={vllm.__version__}, torch={torch.__version__}")
print("依赖匹配，无需 override！")
PYEOF
