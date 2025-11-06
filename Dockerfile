# Build environment for guii3 unified binary
FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libc6-dev \
    libx11-dev \
    libxft-dev \
    libxinerama-dev \
    libxrender-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    ncurses-base \
    pkg-config \
    make \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /workspace

# Copy source files
COPY src/ ./src/
COPY Makefile ./
COPY man/ ./man/

# Set build environment
ENV CC=gcc
ENV CFLAGS="-std=c99 -pedantic -Wall -Os"

# Create build directory
RUN mkdir -p build

# Default command
CMD ["make", "all"]