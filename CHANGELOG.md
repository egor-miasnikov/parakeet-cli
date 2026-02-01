# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-02-01

### Changed

- Removed ffmpeg/ffprobe dependency
- Removed `duration` field from JSON output

### Security

- Fixed command injection via malicious filenames
- Fixed JSON injection in output (now uses jq for safe serialization)
- Fixed path traversal vulnerability
- Added input validation with whitelist for model types
- Unknown flags now return error instead of being silently ignored

### Added

- Unit tests for input validation, security, JSON output
- E2E test with macOS `say` (no ffmpeg needed)
- `PARAKEET_TRANSCRIBE_BIN` environment variable
- Dependency checks on startup (jq, parakeet-transcribe)
- `--` separator support for filenames starting with `-`

## [0.3.1] - 2026-01-15

### Added

- Initial release
- JSON output format with segments and timestamps
- TDT and CTC model support
- Speaker diarization support
- Makefile for build, install, model download
