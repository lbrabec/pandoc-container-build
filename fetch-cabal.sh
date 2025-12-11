#!/bin/bash
# fetch-cabal.sh - Download cabal source and bootstrap dependencies
set -euo pipefail

GHC_VERSION="9.2.8"
CABAL_VERSION="3.10.3.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="${SCRIPT_DIR}/sources/cabal"

echo "=== Fetching cabal ${CABAL_VERSION} source ==="
mkdir -p "${SOURCES_DIR}"
mkdir -p "${SOURCES_DIR}/bootstrap-deps"

# Download cabal source from GitHub
if [[ -f "${SOURCES_DIR}/cabal-${CABAL_VERSION}-src.tar.gz" ]]; then
    echo ">>> Cabal ${CABAL_VERSION} source already exists, skipping..."
else
    echo ">>> Downloading cabal ${CABAL_VERSION} source from GitHub..."
    CABAL_TAG="cabal-install-v${CABAL_VERSION}"
    curl -L --progress-bar \
        "https://github.com/haskell/cabal/archive/refs/tags/${CABAL_TAG}.tar.gz" \
        -o "${SOURCES_DIR}/cabal-${CABAL_VERSION}-src.tar.gz"
fi

# Download bootstrap dependencies
echo ">>> Downloading cabal-install bootstrap dependencies..."
TEMP_DIR=$(mktemp -d)
tar xf "${SOURCES_DIR}/cabal-${CABAL_VERSION}-src.tar.gz" -C "${TEMP_DIR}"
CABAL_SRC_DIR=$(find "${TEMP_DIR}" -maxdepth 1 -type d -name "cabal-*" | head -1)
BOOTSTRAP_JSON="${CABAL_SRC_DIR}/bootstrap/linux-${GHC_VERSION}.json"

if [[ -f "${BOOTSTRAP_JSON}" ]]; then
    echo "Found ${BOOTSTRAP_JSON}, downloading dependencies..."
    python3 "${SCRIPT_DIR}/download_bootstrap_deps.py" "${BOOTSTRAP_JSON}" "${SOURCES_DIR}/bootstrap-deps"
else
    echo "ERROR: Bootstrap config not found: ${BOOTSTRAP_JSON}"
    ls -la "${CABAL_SRC_DIR}/bootstrap/"*.json || true
    exit 1
fi
rm -rf "${TEMP_DIR}"

echo ""
echo "=== Cabal source ready ==="
ls -lh "${SOURCES_DIR}/"
echo "Bootstrap deps: $(ls ${SOURCES_DIR}/bootstrap-deps/*.tar.gz | wc -l) packages"

