#!/bin/bash
# fetch-ghc.sh - Download GHC source only
set -euo pipefail

GHC_VERSION="9.2.8"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="${SCRIPT_DIR}/sources/ghc"

echo "=== Fetching GHC ${GHC_VERSION} source ==="
mkdir -p "${SOURCES_DIR}"

if [[ -f "${SOURCES_DIR}/ghc-${GHC_VERSION}-src.tar.xz" ]]; then
    echo ">>> GHC ${GHC_VERSION} source already exists, skipping..."
else
    echo ">>> Downloading GHC ${GHC_VERSION} source..."
    curl -L --progress-bar \
        "https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-src.tar.xz" \
        -o "${SOURCES_DIR}/ghc-${GHC_VERSION}-src.tar.xz"
fi

echo ""
echo "=== GHC source ready ==="
ls -lh "${SOURCES_DIR}/"

