.PHONY: build install download-models download-models-coreml clean check docker-build docker-push verify-checksums generate-checksums

INSTALL_DIR := $(HOME)/.local/bin
MODELS_DIR := $(HOME)/.parakeet
TMP_DIR := /tmp/parakeet-rs-build

# HuggingFace URLs
TDT_BASE := https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/main
TDT_INT8_BASE := https://huggingface.co/smcleod/parakeet-tdt-0.6b-v2-int8/resolve/main
DIAR_BASE := https://huggingface.co/altunenes/parakeet-rs/resolve/main

build:
	@echo "Building parakeet-rs examples..."
	@if [ ! -d "$(TMP_DIR)" ]; then \
		git clone --depth 1 https://github.com/altunenes/parakeet-rs.git $(TMP_DIR); \
	fi
	cd $(TMP_DIR) && cargo build --release --examples
	@echo "Copying binaries to bin/..."
	cp $(TMP_DIR)/target/release/examples/raw bin/parakeet-transcribe
	cp $(TMP_DIR)/target/release/examples/diarization bin/parakeet-diarize
	@echo "Build complete!"

install: build
	@echo "Installing to $(INSTALL_DIR)..."
	mkdir -p $(INSTALL_DIR)
	cp bin/parakeet-cli $(INSTALL_DIR)/
	cp bin/parakeet-transcribe $(INSTALL_DIR)/
	cp bin/parakeet-diarize $(INSTALL_DIR)/
	chmod +x $(INSTALL_DIR)/parakeet-cli
	chmod +x $(INSTALL_DIR)/parakeet-transcribe
	chmod +x $(INSTALL_DIR)/parakeet-diarize
	@echo ""
	@echo "Installed! Make sure $(INSTALL_DIR) is in your PATH:"
	@echo '  export PATH="$$HOME/.local/bin:$$PATH"'
	@echo ""
	@echo "Next: run 'make download-models' to download the TDT model."

download-models:
	@echo "Downloading TDT model to $(MODELS_DIR)/tdt..."
	mkdir -p $(MODELS_DIR)/tdt
	curl -L -o $(MODELS_DIR)/tdt/encoder-model.onnx "$(TDT_BASE)/encoder-model.onnx"
	curl -L -o $(MODELS_DIR)/tdt/encoder-model.onnx.data "$(TDT_BASE)/encoder-model.onnx.data"
	curl -L -o $(MODELS_DIR)/tdt/decoder_joint-model.onnx "$(TDT_BASE)/decoder_joint-model.onnx"
	curl -L -o $(MODELS_DIR)/tdt/vocab.txt "$(TDT_BASE)/vocab.txt"
	@echo ""
	@echo "TDT model downloaded! (~2.4GB)"
	@echo ""
	@echo "To verify checksums (optional):"
	@echo "  make verify-checksums"

verify-checksums:
	@echo "Verifying model checksums..."
	@if [ -f "$(CURDIR)/checksums/tdt-v3.sha256" ] && grep -q "^[a-f0-9]" "$(CURDIR)/checksums/tdt-v3.sha256" 2>/dev/null; then \
		cd $(MODELS_DIR)/tdt && sha256sum -c $(CURDIR)/checksums/tdt-v3.sha256 && echo "✓ Checksums verified!"; \
	else \
		echo "⚠ No checksums available. Generate with: make generate-checksums"; \
	fi

generate-checksums:
	@echo "Generating checksums for downloaded models..."
	@if [ -d "$(MODELS_DIR)/tdt" ] && [ -f "$(MODELS_DIR)/tdt/encoder-model.onnx" ]; then \
		cd $(MODELS_DIR)/tdt && sha256sum encoder-model.onnx encoder-model.onnx.data decoder_joint-model.onnx vocab.txt > $(CURDIR)/checksums/tdt-v3.sha256; \
		echo "✓ Checksums saved to checksums/tdt-v3.sha256"; \
	else \
		echo "✗ Models not found. Run 'make download-models' first."; \
		exit 1; \
	fi

download-models-coreml:
	@echo "Downloading int8 TDT model for CoreML to $(MODELS_DIR)/tdt..."
	@echo "Note: CoreML requires int8 models without external data files."
	mkdir -p $(MODELS_DIR)/tdt
	curl -L -o $(MODELS_DIR)/tdt/encoder-model.int8.onnx "$(TDT_INT8_BASE)/encoder-model.int8.onnx"
	curl -L -o $(MODELS_DIR)/tdt/decoder_joint-model.int8.onnx "$(TDT_INT8_BASE)/decoder_joint-model.int8.onnx"
	curl -L -o $(MODELS_DIR)/tdt/vocab.txt "$(TDT_INT8_BASE)/vocab.txt"
	@echo ""
	@echo "CoreML-compatible TDT model downloaded! (~630MB)"

download-diarization:
	@echo "Downloading diarization model..."
	curl -L -o $(MODELS_DIR)/diar_streaming_sortformer_4spk-v2.onnx \
		"$(DIAR_BASE)/diar_streaming_sortformer_4spk-v2.onnx"
	@echo "Diarization model downloaded!"

check:
	@echo "Checking installation..."
	@which parakeet-cli > /dev/null && echo "✓ parakeet-cli found" || echo "✗ parakeet-cli not in PATH"
	@which parakeet-transcribe > /dev/null && echo "✓ parakeet-transcribe found" || echo "✗ parakeet-transcribe not in PATH"
	@which jq > /dev/null && echo "✓ jq found" || echo "✗ jq not found (required)"
	@test -f $(MODELS_DIR)/tdt/encoder-model.onnx && echo "✓ TDT model found" || echo "✗ TDT model not found"
	@echo ""
	@parakeet-cli --version 2>/dev/null || echo "Run 'make install' first"

clean:
	rm -rf $(TMP_DIR)
	rm -f bin/parakeet-transcribe bin/parakeet-diarize

test: test-unit test-e2e
	@echo ""
	@echo "All tests passed!"

test-unit:
	@echo "=== Unit Tests ==="
	@PASS=0; FAIL=0; \
	CLI="$(CURDIR)/bin/parakeet-cli"; \
	\
	echo ""; echo "--- Input Validation ---"; \
	\
	printf "Missing --input: "; \
	if $$CLI 2>&1 | jq -e '.error' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf "Nonexistent file: "; \
	if $$CLI --input /nonexistent/file.wav 2>&1 | jq -e '.error' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf "Unknown flag rejected: "; \
	if $$CLI --unknown-flag 2>&1 | jq -e '.error | contains("Unknown option")' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf "Invalid model type: "; \
	touch /tmp/parakeet-test-dummy.wav; \
	RESULT=$$($$CLI --input /tmp/parakeet-test-dummy.wav --model invalid 2>&1); \
	rm -f /tmp/parakeet-test-dummy.wav; \
	if echo "$$RESULT" | jq -e '.error | contains("Invalid model")' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf "Invalid device type: "; \
	RESULT=$$($$CLI --device invalid 2>&1); \
	if echo "$$RESULT" | jq -e '.error | contains("Invalid device")' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	echo ""; echo "--- Path Traversal ---"; \
	\
	printf "Reject ../../../etc/passwd: "; \
	if $$CLI --input "../../../etc/passwd" 2>&1 | jq -e '.error' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	echo ""; echo "--- Command Injection ---"; \
	\
	printf "Reject \$$(cmd).wav: "; \
	if $$CLI --input '$$(whoami).wav' 2>&1 | jq -e '.error' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf "Reject \`cmd\`.wav: "; \
	if $$CLI --input '`whoami`.wav' 2>&1 | jq -e '.error' >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	echo ""; echo "--- JSON Output ---"; \
	\
	printf "Error output is valid JSON: "; \
	if $$CLI 2>&1 | jq . >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf -- "--help exits 0: "; \
	if $$CLI --help >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	printf -- "--version exits 0: "; \
	if $$CLI --version >/dev/null 2>&1; then echo "✓"; PASS=$$((PASS+1)); else echo "✗"; FAIL=$$((FAIL+1)); fi; \
	\
	echo ""; echo "Results: $$PASS passed, $$FAIL failed"; \
	if [ $$FAIL -gt 0 ]; then exit 1; fi

test-e2e:
	@echo ""
	@echo "=== E2E Test ==="
	@if ! which parakeet-transcribe >/dev/null 2>&1; then \
		echo "⚠ Skipping: parakeet-transcribe not in PATH (run 'make install' first)"; \
		exit 0; \
	fi
	@if [ ! -f $(MODELS_DIR)/tdt/encoder-model.onnx ]; then \
		echo "⚠ Skipping: TDT model not found (run 'make download-models' first)"; \
		exit 0; \
	fi
	@echo "Creating test audio..."
	@say -o /tmp/parakeet-test.wav --data-format=LEI16@16000 "Hello, this is a test."
	@echo "Running transcription..."
	@OUTPUT=$$(parakeet-cli --input /tmp/parakeet-test.wav); \
	rm -f /tmp/parakeet-test.wav; \
	echo "$$OUTPUT" | jq .; \
	if echo "$$OUTPUT" | jq -e '.text and .segments' >/dev/null 2>&1; then \
		echo "✓ E2E test passed"; \
	else \
		echo "✗ E2E test failed: invalid JSON structure"; \
		exit 1; \
	fi

# Docker targets
DOCKER_IMAGE := ghcr.io/egor-miasnikov/parakeet-cli

docker-build:
	@echo "Building Docker images..."
	docker build --target runtime -t $(DOCKER_IMAGE):slim .
	docker build --target full -t $(DOCKER_IMAGE):full .
	@echo ""
	@echo "Built images:"
	@echo "  $(DOCKER_IMAGE):slim  (~100MB, models via volume)"
	@echo "  $(DOCKER_IMAGE):full  (~2.5GB, models included)"

docker-push: docker-build
	@echo "Pushing Docker images..."
	docker push $(DOCKER_IMAGE):slim
	docker push $(DOCKER_IMAGE):full
