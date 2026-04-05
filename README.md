# vLLM 0.19.0 for Jetson Orin

Build and run vLLM 0.19.0 on NVIDIA Jetson Orin — **ready within 72 hours of Gemma 4 release**.

## Quick Start: Docker (recommended)

No compilation needed. Pull and run:

```bash
sudo docker pull ghcr.io/yuyirobotlab/vllm-orin:0.19.0

sudo docker run --rm --runtime nvidia --gpus all \
    -v /path/to/models:/models \
    -p 8000:8000 \
    ghcr.io/yuyirobotlab/vllm-orin:0.19.0 \
    --model /models/gemma-4-E4B-it-W4A16 \
    --host 0.0.0.0 --port 8000 \
    --served-model-name gemma-4-e4b \
    --max-model-len 4096 \
    --gpu-memory-utilization 0.65 \
    --enable-prefix-caching
```

## Pre-built Wheels

Install without Docker or compilation:

```bash
pip install https://huggingface.co/YuyiRobot/vllm-jetson-orin/resolve/main/torch-2.10.0-cp310-cp310-linux_aarch64.whl
pip install https://huggingface.co/YuyiRobot/vllm-jetson-orin/resolve/main/vllm-0.19.0+cu126-cp310-cp310-linux_aarch64.whl
```

Wheels are also available in the [GitHub Releases](https://github.com/YuyiRobotLab/vllm-orin-release/releases) of this repo.

See full install guide on [HuggingFace](https://huggingface.co/YuyiRobot/vllm-jetson-orin).

## Build from Source

Only needed if you want to customize the build:

```bash
git clone https://github.com/YuyiRobotLab/vllm-orin-release.git
cd vllm-orin-release

# Default: builds to ./dist, uses /data as workspace
bash build_vllm.sh

# Custom paths:
BUILD_DIR=/mnt/ssd OUTPUT_DIR=./wheels bash build_vllm.sh
```

### Requirements

- NVIDIA Jetson Orin (AGX Orin 64GB / 32GB, Orin NX)
- JetPack 6.2+ (CUDA 12.6)
- Python 3.10
- ~20GB free disk space for build

### Configurable Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BUILD_DIR` | `/data` | Build workspace (~20GB needed) |
| `OUTPUT_DIR` | `./dist` | Where the .whl file goes |
| `MAX_JOBS` | `9` | Parallel compile jobs |
| `PYPI_MIRROR` | Tsinghua mirror | PyPI mirror (leave empty for default) |

### Build Time

~75 minutes on Jetson AGX Orin 64GB.

## Benchmark (Jetson AGX Orin 64GB)

**Gemma-4-E4B-IT-W4A16 (GPTQ W4A16)**

| Test | Speed |
|------|-------|
| Prefill | 432.2 tok/s |
| Decode | 30.9 tok/s |
| TTFT | 3,511 ms |

## Links

- [Docker image (ghcr.io)](https://github.com/orgs/YuyiRobotLab/packages/container/package/vllm-orin)
- [Pre-built wheels on HuggingFace](https://huggingface.co/YuyiRobot/vllm-jetson-orin)
- [vLLM upstream](https://github.com/vllm-project/vllm)
- [Jetson AI Lab PyTorch](https://pypi.jetson-ai-lab.io/jp6/cu126)

## License

Apache 2.0
