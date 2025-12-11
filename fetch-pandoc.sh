#!/bin/bash
# fetch-pandoc.sh - Download pandoc dependencies from deps.txt
# Run generate-pandoc-deps.sh first to create the deps.txt file
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_FILE="${SCRIPT_DIR}/pandoc-deps.txt"
SOURCES_DIR="${SCRIPT_DIR}/sources/pandoc"
HACKAGE_DIR="${SOURCES_DIR}/hackage-packages"

if [[ ! -f "${DEPS_FILE}" ]]; then
    echo "Error: ${DEPS_FILE} not found"
    echo "Run ./generate-pandoc-deps.sh first"
    exit 1
fi

echo "=== Downloading pandoc dependencies ==="

# Create output directory
mkdir -p "${HACKAGE_DIR}"

# Count packages
TOTAL=$(grep -c "^https://" "${DEPS_FILE}" || echo 0)
COUNT=0

# Download each package
while read -r url; do
    # Skip comments and empty lines
    [[ "$url" =~ ^#.*$ ]] && continue
    [[ -z "$url" ]] && continue
    
    COUNT=$((COUNT + 1))
    FILENAME=$(basename "$url")
    
    if [[ -f "${HACKAGE_DIR}/${FILENAME}" ]]; then
        echo "[${COUNT}/${TOTAL}] ${FILENAME} (exists)"
        continue
    fi
    
    echo "[${COUNT}/${TOTAL}] ${FILENAME}"
    curl -sL "$url" -o "${HACKAGE_DIR}/${FILENAME}" || {
        echo "  WARNING: Failed to download ${url}"
    }
done < "${DEPS_FILE}"

echo ""
echo "=== Download complete ==="
DOWNLOADED=$(ls "${HACKAGE_DIR}"/*.tar.gz 2>/dev/null | wc -l)
echo "Packages downloaded: ${DOWNLOADED}/${TOTAL}"
