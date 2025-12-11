#!/bin/bash
# generate-pandoc-deps.sh - Generate list of pandoc dependency URLs
# Uses cabal container to resolve dependencies, outputs flat list of Hackage URLs
set -euo pipefail

PANDOC_VERSION="${PANDOC_VERSION:-3.7.0.2}"
CABAL_IMAGE="${CABAL_IMAGE:-localhost/cabal:3.10.3.0-ubi9}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/pandoc-deps.txt"

echo "=== Generating pandoc ${PANDOC_VERSION} dependency list ==="
echo "Using container: ${CABAL_IMAGE}"

mkdir -p "${SCRIPT_DIR}/sources/pandoc"

# Run cabal in container to get build plan
podman run --rm \
    -v "${SCRIPT_DIR}/pandoc.cabal.project:/build/pandoc.cabal.project:ro,Z" \
    "${CABAL_IMAGE}" \
    sh -c '
set -e
cd /tmp

cabal update >/dev/null 2>&1

cabal get pandoc-cli-'"${PANDOC_VERSION}"' >/dev/null 2>&1
cd pandoc-cli-'"${PANDOC_VERSION}"'

# Use cabal.project, removing local-hackage repo
sed "/^repository local-hackage/,/^$/d" /build/pandoc.cabal.project > cabal.project

# Get build plan and extract package names (enable tests/benchmarks to capture all deps)
cabal build --dry-run 2>/dev/null | \
    grep "^ - " | \
    sed "s/^ - //" | \
    sed "s/ (.*$//" | \
    sort -u
' > "${OUTPUT_FILE}.tmp"

# Convert to Hackage URLs
echo "# Pandoc ${PANDOC_VERSION} dependencies" > "${OUTPUT_FILE}"
echo "# Generated: $(date -Iseconds)" >> "${OUTPUT_FILE}"
echo "# One URL per line - download with curl" >> "${OUTPUT_FILE}"
echo "" >> "${OUTPUT_FILE}"

while read -r pkg; do
    [ -z "$pkg" ] && continue
    echo "https://hackage.haskell.org/package/${pkg}/${pkg}.tar.gz" >> "${OUTPUT_FILE}"
done < "${OUTPUT_FILE}.tmp"

rm -f "${OUTPUT_FILE}.tmp"

# Add packages not captured by dry-run
cat >> "${OUTPUT_FILE}" << 'EXTRA'

# Additional deps not captured by cabal dry-run
https://hackage.haskell.org/package/tasty-1.5.3/tasty-1.5.3.tar.gz
https://hackage.haskell.org/package/optparse-applicative-0.18.1.0/optparse-applicative-0.18.1.0.tar.gz
https://hackage.haskell.org/package/prettyprinter-ansi-terminal-1.1.3/prettyprinter-ansi-terminal-1.1.3.tar.gz
https://hackage.haskell.org/package/ansi-wl-pprint-1.0.2/ansi-wl-pprint-1.0.2.tar.gz
https://hackage.haskell.org/package/unbounded-delays-0.1.1.1/unbounded-delays-0.1.1.1.tar.gz
https://hackage.haskell.org/package/wcwidth-0.0.2/wcwidth-0.0.2.tar.gz
EXTRA

# Count packages
PKGCOUNT=$(grep -c "^https://" "${OUTPUT_FILE}" || echo 0)

echo ""
echo "=== Generated ${PKGCOUNT} package URLs ==="
echo "Output: ${OUTPUT_FILE}"
echo ""
echo "To download, run: ./fetch-pandoc.sh"

