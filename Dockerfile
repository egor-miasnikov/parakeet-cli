# syntax=docker/dockerfile:1

# =============================================================================
# Stage 1: Build parakeet-rs binaries
# =============================================================================
FROM rust:1.79-slim AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        ca-certificates \
        pkg-config \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone and build parakeet-rs (only the examples we need)
RUN git clone --depth 1 https://github.com/altunenes/parakeet-rs.git . && \
    cargo build --release --example raw --example diarization

# =============================================================================
# Stage 2: Runtime image
# =============================================================================
FROM ubuntu:24.04 AS runtime

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        jq \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Copy binaries from builder
COPY --from=builder /build/target/release/examples/raw /usr/local/bin/parakeet-transcribe
COPY --from=builder /build/target/release/examples/diarization /usr/local/bin/parakeet-diarize

# Copy CLI wrapper
COPY bin/parakeet-cli /usr/local/bin/parakeet-cli
RUN chmod +x /usr/local/bin/parakeet-cli \
             /usr/local/bin/parakeet-transcribe \
             /usr/local/bin/parakeet-diarize

# Set environment
ENV PARAKEET_MODELS_DIR=/models
ENV PARAKEET_TRANSCRIBE_BIN=/usr/local/bin/parakeet-transcribe

# Create non-root user for security
RUN useradd -r -m parakeet

# Create models directory with proper ownership
RUN mkdir -p /models /data && \
    chown -R parakeet:parakeet /models /data

# Validate installation (before switching user)
RUN parakeet-cli --version

# Switch to non-root user
USER parakeet

WORKDIR /data

ENTRYPOINT ["parakeet-cli"]
CMD ["--help"]

# =============================================================================
# Stage 3: Full image with models (optional)
# Build with: docker build --target full -t parakeet-cli:full .
# =============================================================================
FROM runtime AS full

# HuggingFace model URLs
ARG TDT_BASE=https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/main

# Download TDT model (~2.4GB) as root, then fix ownership
USER root
RUN mkdir -p /models/tdt && \
    curl -L -o /models/tdt/encoder-model.onnx "${TDT_BASE}/encoder-model.onnx" && \
    curl -L -o /models/tdt/encoder-model.onnx.data "${TDT_BASE}/encoder-model.onnx.data" && \
    curl -L -o /models/tdt/decoder_joint-model.onnx "${TDT_BASE}/decoder_joint-model.onnx" && \
    curl -L -o /models/tdt/vocab.txt "${TDT_BASE}/vocab.txt" && \
    chown -R parakeet:parakeet /models

# Switch back to non-root user
USER parakeet

WORKDIR /data

ENTRYPOINT ["parakeet-cli"]
CMD ["--help"]
