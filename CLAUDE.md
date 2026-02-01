# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

parakeet-cli is a bash wrapper around [parakeet-rs](https://github.com/altunenes/parakeet-rs) that provides JSON-formatted speech-to-text output using NVIDIA Parakeet models. The wrapper (`bin/parakeet-cli`) parses raw transcription output and formats it as structured JSON with metadata.

## Build Commands

```bash
make build              # Clone parakeet-rs, build with cargo, copy binaries to bin/
make install            # Build + install to ~/.local/bin/
make download-models    # Download TDT model (~2.4GB) to ~/.parakeet/tdt/
make download-diarization  # Download diarization model
make check              # Verify installation (binaries, jq, models)
make clean              # Remove build artifacts and binaries
```

## Testing

```bash
make test               # Run all tests (unit + e2e)
make test-unit          # Input validation, security, JSON output (no models needed)
make test-e2e           # Full transcription test (requires models + macOS `say`)
```

Unit tests cover: command injection, path traversal, invalid flags, JSON validity.

## Architecture

```
bin/
├── parakeet-cli         # Bash wrapper script (source controlled)
├── parakeet-transcribe  # Compiled Rust binary from parakeet-rs (gitignored, built locally)
└── parakeet-diarize     # Compiled Rust binary from parakeet-rs (gitignored, built locally)
```

The main script `bin/parakeet-cli` is a bash wrapper that:
1. Parses CLI arguments (--input, --model, --diarize, etc.)
2. Calls `parakeet-transcribe` with appropriate model type (tdt/ctc)
3. Parses the raw text output using grep/sed
4. Formats results as JSON with segments, duration, and timing metadata

The Rust binaries are not committed - they're built from parakeet-rs during `make build`.

## Environment

- `PARAKEET_MODELS_DIR`: Override default models location (default: `~/.parakeet`)
- `PARAKEET_TRANSCRIBE_BIN`: Override path to parakeet-transcribe binary (default: searches PATH)
- Models stored in `~/.parakeet/tdt/` (encoder, decoder, vocab files)
- Requires: jq (JSON serialization)
