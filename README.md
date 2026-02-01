# parakeet-cli

[![CI](https://github.com/egor-miasnikov/parakeet-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/egor-miasnikov/parakeet-cli/actions/workflows/ci.yml)
[![Docker](https://github.com/egor-miasnikov/parakeet-cli/actions/workflows/docker.yml/badge.svg)](https://github.com/egor-miasnikov/parakeet-cli/actions/workflows/docker.yml)
[![Release](https://img.shields.io/github/v/release/egor-miasnikov/parakeet-cli)](https://github.com/egor-miasnikov/parakeet-cli/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

CLI wrapper for [parakeet-rs](https://github.com/altunenes/parakeet-rs) — fast speech-to-text using NVIDIA Parakeet models with structured JSON output.

## Features

- **JSON output** — structured output for easy integration with scripts and services
- **TDT model** — multilingual support (25 languages), high accuracy
- **CTC model** — English-only, faster inference
- **Speaker diarization** — identify multiple speakers
- **Timestamps** — word and sentence-level timing

## Quick Start

```bash
# Install
make build && make install

# Download models (~2.4GB)
make download-models

# Transcribe
parakeet-cli --input audio.wav
```

## Installation

### From Release (recommended)

Download pre-built binaries from [Releases](https://github.com/egor-miasnikov/parakeet-cli/releases):

```bash
# Linux x86_64
curl -LO https://github.com/egor-miasnikov/parakeet-cli/releases/latest/download/parakeet-cli-linux-x86_64.tar.gz
tar xzf parakeet-cli-linux-x86_64.tar.gz
cd parakeet-cli-*-linux-x86_64
./install.sh

# macOS ARM (Apple Silicon) - CPU
curl -LO https://github.com/egor-miasnikov/parakeet-cli/releases/latest/download/parakeet-cli-macos-arm64.tar.gz
tar xzf parakeet-cli-macos-arm64.tar.gz
cd parakeet-cli-*-macos-arm64
./install.sh

# macOS ARM with CoreML (Metal GPU acceleration)
curl -LO https://github.com/egor-miasnikov/parakeet-cli/releases/latest/download/parakeet-cli-macos-arm64-coreml.tar.gz
tar xzf parakeet-cli-macos-arm64-coreml.tar.gz
cd parakeet-cli-*-macos-arm64-coreml
./install.sh
```

### From Source

#### Prerequisites

| Dependency | Purpose | Install |
|------------|---------|---------|
| **Rust** | Build parakeet-rs | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| **jq** | JSON output | `brew install jq` / `apt install jq` |

### Build & Install

```bash
make build      # Clone parakeet-rs, build binaries
make install    # Install to ~/.local/bin/
```

Add to your shell profile if needed:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Download Models

```bash
make download-models        # TDT model (~2.4GB, multilingual)
make download-diarization   # Diarization model (optional)
```

### Verify Installation

```bash
make check
```

### Docker

Available image variants:

| Image | Size | GPU | Models | Platforms |
|-------|------|-----|--------|-----------|
| `slim` / `latest` | ~200MB | ❌ | Volume | amd64, arm64 |
| `full` | ~2.6GB | ❌ | Included | amd64, arm64 |
| `cuda` | ~4GB | ✅ | Volume | amd64 |
| `cuda-full` | ~7GB | ✅ | Included | amd64 |

```bash
# CPU - mount models from host
docker run --rm \
  -v ~/.parakeet:/models:ro \
  -v $(pwd):/data:ro \
  ghcr.io/egor-miasnikov/parakeet-cli:slim \
  --input /data/audio.wav

# CPU - models included
docker run --rm \
  -v $(pwd):/data:ro \
  ghcr.io/egor-miasnikov/parakeet-cli:full \
  --input /data/audio.wav

# GPU (NVIDIA) - requires nvidia-docker
docker run --rm --gpus all \
  -v ~/.parakeet:/models:ro \
  -v $(pwd):/data:ro \
  ghcr.io/egor-miasnikov/parakeet-cli:cuda \
  --input /data/audio.wav --device cuda
```

Build locally:
```bash
make docker-build
```

## Usage

### Basic

```bash
# JSON output (default)
parakeet-cli --input audio.wav

# Plain text output
parakeet-cli --input audio.wav --output-format text

# Use CTC model (English, faster)
parakeet-cli --input audio.wav --model ctc
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--input <file>` | Input audio file (WAV 16kHz mono recommended) | required |
| `--output-format <fmt>` | Output format: `json` or `text` | `json` |
| `--model <type>` | Model: `tdt`, `tdt-0.6b`, `ctc`, `ctc-1.1b` | `tdt` |
| `--models-dir <dir>` | Models directory | `~/.parakeet` |
| `--timestamps <mode>` | Timestamp mode: `words` or `sentences` | `words` |
| `--diarize` | Enable speaker diarization | off |
| `--max-speakers <n>` | Max speakers for diarization | `4` |
| `--device <dev>` | Device: `cpu`, `cuda`, or `coreml` | `cpu` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PARAKEET_MODELS_DIR` | Models directory | `~/.parakeet` |
| `PARAKEET_TRANSCRIBE_BIN` | Path to parakeet-transcribe | searched in PATH |

## JSON Output

### Success

```json
{
    "text": "Hello, this is a test.",
    "model": "parakeet-tdt",
    "device": "cpu",
    "processing_time_ms": 1200,
    "segments": [
        {"start": 0.00, "end": 3.60, "text": "Hello, this is a test."}
    ]
}
```

### Error

Errors are returned as JSON on stderr with exit code 1:

```json
{"error": "Input file not found: audio.wav"}
```

## Integration Examples

### Bash

```bash
result=$(parakeet-cli --input audio.wav)
text=$(echo "$result" | jq -r '.text')
```

### TypeScript/Node.js

```typescript
import { execSync } from 'child_process';

const result = execSync('parakeet-cli --input audio.wav', { encoding: 'utf-8' });
const { text, segments } = JSON.parse(result);
```

### Go

```go
cmd := exec.Command("parakeet-cli", "--input", "audio.wav")
output, err := cmd.Output()
if err != nil {
    log.Fatal(err)
}

var result struct {
    Text     string `json:"text"`
    Segments []struct {
        Start float64 `json:"start"`
        End   float64 `json:"end"`
        Text  string  `json:"text"`
    } `json:"segments"`
}
json.Unmarshal(output, &result)
```

### Python

```python
import subprocess
import json

result = subprocess.run(
    ['parakeet-cli', '--input', 'audio.wav'],
    capture_output=True, text=True, check=True
)
data = json.loads(result.stdout)
print(data['text'])
```

## GPU Acceleration

### NVIDIA CUDA (Linux)

Use the `linux-x86_64-cuda` release with NVIDIA GPUs:

```bash
# Install CUDA version
curl -LO https://github.com/egor-miasnikov/parakeet-cli/releases/latest/download/parakeet-cli-linux-x86_64-cuda.tar.gz

# Run with GPU
parakeet-cli --input audio.wav --device cuda
```

### Apple CoreML (macOS)

Use the `macos-arm64-coreml` release for Metal GPU acceleration on Apple Silicon:

```bash
# Install CoreML version
curl -LO https://github.com/egor-miasnikov/parakeet-cli/releases/latest/download/parakeet-cli-macos-arm64-coreml.tar.gz
tar xzf parakeet-cli-macos-arm64-coreml.tar.gz
cd parakeet-cli-*-macos-arm64-coreml
./install.sh

# Download CoreML-compatible int8 models (~630MB instead of ~2.4GB)
make download-models-coreml

# Run with Metal GPU (automatic, no --device flag needed)
parakeet-cli --input audio.wav
```

**Notes:**
- CoreML requires int8 quantized models (no external data files)
- First run compiles the model for CoreML (~3s), subsequent runs use cached compilation
- Requires macOS 12+ and Apple Silicon (M1/M2/M3/M4)
- Typical speedup: **2-4x** vs CPU

## Audio Format

For best results, use 16kHz mono WAV. Convert with ffmpeg:

```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

## Development

```bash
make test           # Run all tests
make test-unit      # Unit tests only (no models needed)
make test-e2e       # E2E test (requires models, macOS)
make clean          # Remove build artifacts
```

## License

MIT — see [LICENSE](LICENSE)

## Credits

- [parakeet-rs](https://github.com/altunenes/parakeet-rs) by altunenes
- [NVIDIA Parakeet](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2) models
