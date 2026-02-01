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

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
