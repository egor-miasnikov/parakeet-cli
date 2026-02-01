# Contributing to parakeet-cli

## Getting Started

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/parakeet-cli.git
cd parakeet-cli

# Build
make build

# Run tests
make test-unit
```

## Development Workflow

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes to `bin/parakeet-cli`
3. Run tests: `make test-unit`
4. Commit with clear message
5. Open a Pull Request

## Code Style

- Use `shellcheck` for linting: `shellcheck bin/parakeet-cli`
- Quote all variables: `"$VAR"` not `$VAR`
- Use `[[ ]]` for conditions, not `[ ]`
- Error messages as JSON to stderr
- Exit codes: 0 for success, 1 for errors

## Testing

```bash
make test-unit    # Validation, security, JSON output (no models)
make test-e2e     # Full transcription (requires models)
make test         # Both
```

### Adding Tests

Add new tests to the `test-unit` target in `Makefile`:

```makefile
printf "My new test: "; \
if <test condition>; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
```

## Pull Request Guidelines

- One feature/fix per PR
- Update CHANGELOG.md
- Ensure `make test-unit` passes
- Update README.md if adding new options

## Security

If you find a security vulnerability, please open an issue or contact the maintainers directly.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
