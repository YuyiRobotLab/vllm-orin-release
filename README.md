# vLLM 0.19.0 for Jetson Orin

Build vLLM 0.19.0 from source on NVIDIA Jetson Orin — **ready within 72 hours of Gemma 4 release**.

## Pre-built Wheels (recommended)

Skip the build and install directly:

```bash
pip install https://huggingface.co/YuyiRobot/vllm-jetson-orin/resolve/main/torch-2.10.0-cp310-cp310-linux_aarch64.whl
pip install https://huggingface.co/YuyiRobot/vllm-jetson-orin/resolve/main/vllm-0.19.0+cu126-cp310-cp310-linux_aarch64.whl
```

See full install guide on [HuggingFace](https://huggingface.co/YuyiRobot/vllm-jetson-orin).

## Build from Source

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

- [Pre-built wheels on HuggingFace](https://huggingface.co/YuyiRobot/vllm-jetson-orin)
- [vLLM upstream](https://github.com/vllm-project/vllm)
- [Jetson AI Lab PyTorch](https://pypi.jetson-ai-lab.io/jp6/cu126)

## License

Apache 2.0
