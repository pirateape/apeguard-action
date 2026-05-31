#!/bin/bash
# ApeGuard GitHub Action — Binary Installer
# Downloads the appropriate ApeGuard binary for the runner's OS/arch.
set -euo pipefail

VERSION="${APEGUARD_VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.apeguard}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64|amd64) TARGET="x86_64-unknown-linux-gnu" ;;
      aarch64|arm64) TARGET="aarch64-unknown-linux-gnu" ;;
      *) echo "❌ Unsupported architecture: $ARCH on Linux"; exit 1 ;;
    esac
    ;;
  darwin)
    case "$ARCH" in
      x86_64) TARGET="x86_64-apple-darwin" ;;
      arm64)  TARGET="aarch64-apple-darwin" ;;
      *) echo "❌ Unsupported architecture: $ARCH on macOS"; exit 1 ;;
    esac
    ;;
  *)
    echo "❌ Unsupported OS: $OS (ApeGuard supports Linux and macOS runners)"
    exit 1
    ;;
esac

# Determine download URL
if [ "$VERSION" = "latest" ]; then
  BASE_URL="https://github.com/pirateape/ape-guard/releases/latest/download"
else
  BASE_URL="https://github.com/pirateape/ape-guard/releases/download/v${VERSION}"
fi

DOWNLOAD_URL="${BASE_URL}/apeguard-${TARGET}"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download binary
echo "::group::📦 Installing ApeGuard"
echo "  Version: ${VERSION}"
echo "  Platform: ${TARGET}"
echo "  Download: ${DOWNLOAD_URL}"

curl -sSfL -o "${INSTALL_DIR}/apeguard" "$DOWNLOAD_URL" || {
  echo "❌ Failed to download ApeGuard from ${DOWNLOAD_URL}"
  echo "   Check version exists at: https://github.com/pirateape/ape-guard/releases"
  exit 1
}

chmod +x "${INSTALL_DIR}/apeguard"

# Verify installation
"${INSTALL_DIR}/apeguard" version

echo "✅ ApeGuard installed successfully"
echo "::endgroup::"

# Add to PATH for subsequent steps
echo "${INSTALL_DIR}" >> "$GITHUB_PATH"
echo "APEGUARD_BIN=${INSTALL_DIR}/apeguard" >> "$GITHUB_ENV"
