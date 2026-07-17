#!/usr/bin/env bash
# install-skyscraper-macos.sh
# Build and install Gemba/Skyscraper to ~/.local (no sudo).
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
SYSCONFDIR="${SYSCONFDIR:-$PREFIX/etc}"
SRC_DIR="${SRC_DIR:-$HOME/skysource}"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

echo "==> Skyscraper macOS installer"
echo "    PREFIX=${PREFIX}"
echo "    SYSCONFDIR=${SYSCONFDIR}"
echo "    SRC_DIR=${SRC_DIR}"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install from https://brew.sh then re-run." >&2
  exit 1
fi

echo "==> Installing Homebrew dependencies..."
brew install gnu-tar wget qt

# Prefer Homebrew LLVM if system SDK is too old for Qt 6
SDK_VER="$(xcrun --show-sdk-version 2>/dev/null || echo 0)"
SDK_MAJOR="${SDK_VER%%.*}"
USE_LLVM=0
if [[ "${FORCE_HOMEBREW_LLVM:-0}" == "1" ]] || [[ "${SDK_MAJOR}" -lt 14 ]]; then
  echo "==> System SDK is ${SDK_VER} (< 14) or FORCE_HOMEBREW_LLVM=1 — installing llvm..."
  brew install llvm
  USE_LLVM=1
fi

export PATH="/opt/homebrew/opt/qt/bin:/opt/homebrew/opt/gnu-tar/libexec/gnubin:/opt/homebrew/bin:${PATH}"
if [[ "${USE_LLVM}" -eq 1 ]]; then
  export PATH="/opt/homebrew/opt/llvm/bin:${PATH}"
  export CC="/opt/homebrew/opt/llvm/bin/clang"
  export CXX="/opt/homebrew/opt/llvm/bin/clang++"
else
  export CC="${CC:-clang}"
  export CXX="${CXX:-clang++}"
fi

echo "==> Fetching Skyscraper source into ${SRC_DIR}..."
mkdir -p "${SRC_DIR}"
cd "${SRC_DIR}"

if [[ ! -f skyscraper.pro ]]; then
  # Prefer official update script (latest release tarball)
  if command -v wget >/dev/null 2>&1; then
    wget -q -O - https://raw.githubusercontent.com/Gemba/skyscraper/master/update_skyscraper.sh \
      | PREFIX="${PREFIX}" bash -s -- || true
  fi
fi

# If update script failed or left incomplete tree, clone
if [[ ! -f skyscraper.pro ]]; then
  echo "==> Cloning Gemba/skyscraper..."
  rm -rf "${SRC_DIR}.tmp"
  git clone --depth 1 https://github.com/Gemba/skyscraper.git "${SRC_DIR}.tmp"
  # Move contents into SRC_DIR
  shopt -s dotglob
  mv "${SRC_DIR}.tmp"/* "${SRC_DIR}/"
  rmdir "${SRC_DIR}.tmp" 2>/dev/null || rm -rf "${SRC_DIR}.tmp"
fi

cd "${SRC_DIR}"
[[ -f VERSION.ini ]] || echo 'VERSION=dev' > VERSION.ini

echo "==> Configuring (qmake)..."
make distclean 2>/dev/null || true
rm -f Makefile .qmake.stash

# PREFIX/SYSCONFDIR MUST be environment variables for skyscraper.pro
export PREFIX SYSCONFDIR
PREFIX="${PREFIX}" SYSCONFDIR="${SYSCONFDIR}" qmake6 \
  "QMAKE_CC=${CC}" \
  "QMAKE_CXX=${CXX}" \
  "QMAKE_LINK=${CXX}" \
  "QMAKE_CXXFLAGS+=-stdlib=libc++" \
  "QMAKE_LFLAGS+=-stdlib=libc++" \
  skyscraper.pro

if ! grep -q "PREFIX=\\\"${PREFIX}\\\"" Makefile 2>/dev/null; then
  echo "WARNING: PREFIX may not be embedded correctly. Check Makefile DEFINES." >&2
  grep 'DEFINES' Makefile | head -2 || true
fi

echo "==> Building..."
make -j"${JOBS}"

BIN_SRC=""
if [[ -x Skyscraper.app/Contents/MacOS/Skyscraper ]]; then
  BIN_SRC="Skyscraper.app/Contents/MacOS/Skyscraper"
elif [[ -x Skyscraper ]]; then
  BIN_SRC="Skyscraper"
else
  echo "Build finished but binary not found." >&2
  exit 1
fi

echo "==> Installing binary and assets to ${PREFIX}..."
mkdir -p "${PREFIX}/bin" "${SYSCONFDIR}/skyscraper"/{cache,import,resources}
cp -f "${BIN_SRC}" "${PREFIX}/bin/Skyscraper"
chmod +x "${PREFIX}/bin/Skyscraper"

ETC="${SYSCONFDIR}/skyscraper"
cp -f aliasMap.csv hints.xml mameMap.csv mobygames_platforms.json peas.json \
  platforms_idmap.csv screenscraper_platforms.json tgdb_developers.json \
  tgdb_genres.json tgdb_platforms.json tgdb_publishers.json \
  config.ini.example README.md artwork.xml \
  batocera-artwork.xml retroarch-artwork.xml \
  "${ETC}/" 2>/dev/null || true
cp -f artwork.xml.example1 artwork.xml.example2 artwork.xml.example3 artwork.xml.example4 \
  "${ETC}/" 2>/dev/null || true
cp -f docs/ARTWORK.md docs/CACHE.md "${ETC}/" 2>/dev/null || true
cp -f cache/priorities.xml.example "${ETC}/cache/" 2>/dev/null || true
cp -f docs/CACHE.md "${ETC}/cache/" 2>/dev/null || true
cp -f docs/IMPORT.md import/definitions.dat.example1 import/definitions.dat.example2 \
  "${ETC}/import/" 2>/dev/null || true
cp -f resources/*.png "${ETC}/resources/" 2>/dev/null || true

# PATH
if ! grep -q '\.local/bin' "${HOME}/.zshrc" 2>/dev/null; then
  {
    echo ''
    echo '# Skyscraper (and other user-local tools)'
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "${HOME}/.zshrc"
  echo "==> Added ~/.local/bin to ~/.zshrc"
fi

export PATH="${PREFIX}/bin:${PATH}"
echo "==> Verifying..."
Skyscraper --buildinfo
Skyscraper --help >/dev/null

echo ""
echo "✓ Skyscraper installed to ${PREFIX}/bin/Skyscraper"
echo ""
echo "Next steps:"
echo "  1. cp config/config.ini.example ~/.skyscraper/config.ini"
echo "  2. Edit userCreds and inputFolder in ~/.skyscraper/config.ini"
echo "  3. cp scripts/scrape-eeroms ~/.local/bin && chmod +x ~/.local/bin/scrape-eeroms"
echo "  4. source ~/.zshrc   # or open a new terminal"
echo "  5. scrape-eeroms --list"
