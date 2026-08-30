#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# AnycubicSlicerNext LinuxFix
# Automatic AppImage builder
#
# Usage:
#   ./build.sh AnycubicSlicer.AppImage
#
# Result:
#   AnycubicSlicerNext-<version>-linux-x86_64-linuxfix.AppImage
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SOURCE="${1:-}"

if [[ -z "$SOURCE" ]]; then
    echo
    echo "Usage:"
    echo
    echo "  ./build.sh AnycubicSlicer.AppImage"
    echo
    exit 1
fi

SOURCE="$(realpath "$SOURCE")"

if [[ ! -f "$SOURCE" ]]; then
    echo
    echo "ERROR: AppImage not found:"
    echo "$SOURCE"
    echo
    exit 1
fi

# ============================================================
# Configuration
# ============================================================

WORK_DIR="$SCRIPT_DIR/.linuxfix-build"
APPDIR="$WORK_DIR/squashfs-root"
TOOLS_DIR="$SCRIPT_DIR/.tools"

APPIMAGETOOL="$TOOLS_DIR/appimagetool-x86_64.AppImage"

# Official AppImageKit release.
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

# ============================================================
# Check architecture
# ============================================================

ARCH="$(uname -m)"

if [[ "$ARCH" != "x86_64" ]]; then
    echo
    echo "ERROR: This builder currently supports x86_64 only."
    echo "Detected architecture: $ARCH"
    echo
    exit 1
fi

# ============================================================
# Find or download appimagetool
# ============================================================

mkdir -p "$TOOLS_DIR"

if command -v appimagetool >/dev/null 2>&1; then

    APPIMAGETOOL="$(command -v appimagetool)"

elif [[ -x "$APPIMAGETOOL" ]]; then

    :

else

    echo
    echo "appimagetool not found."
    echo "Downloading official appimagetool..."
    echo

    if ! command -v curl >/dev/null 2>&1; then
        echo "ERROR: curl is required."
        echo
        echo "Install it with:"
        echo
        echo "  sudo apt install curl"
        echo
        exit 1
    fi

    curl \
        --fail \
        --location \
        --progress-bar \
        "$APPIMAGETOOL_URL" \
        --output "$APPIMAGETOOL"

    chmod +x "$APPIMAGETOOL"

    echo
    echo "appimagetool downloaded."
    echo
fi

# ============================================================
# Check FUSE
# ============================================================

if ! command -v fusermount3 >/dev/null 2>&1; then
    echo
    echo "ERROR: fuse3 is required."
    echo
    echo "Install it with:"
    echo
    echo "  sudo apt install fuse3"
    echo
    exit 1
fi

# ============================================================
# Clean previous build
# ============================================================

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo
echo "============================================================"
echo " AnycubicSlicerNext LinuxFix Builder"
echo "============================================================"
echo
echo "Source:"
echo "  $SOURCE"
echo
echo "Working directory:"
echo "  $WORK_DIR"
echo

# ============================================================
# Extract original AppImage
# ============================================================

echo "[1/5] Extracting original AppImage..."

cd "$WORK_DIR"

"$SOURCE" --appimage-extract >/dev/null

if [[ ! -d "$APPDIR" ]]; then
    echo
    echo "ERROR: AppImage extraction failed."
    echo
    exit 1
fi

# ============================================================
# Check original AppRun
# ============================================================

echo "[2/5] Preparing AppRun..."

if [[ ! -f "$APPDIR/AppRun" ]]; then
    echo
    echo "ERROR: Original AppImage does not contain AppRun."
    echo
    exit 1
fi

mv "$APPDIR/AppRun" "$APPDIR/AppRun.original"

# ============================================================
# Install compatibility launcher
# ============================================================

echo "[3/5] Installing Linux compatibility launcher..."

cat > "$APPDIR/AppRun" <<'LAUNCHER'
#!/bin/sh

# ============================================================
# AnycubicSlicerNext Linux Compatibility Launcher
# ============================================================

APPDIR="$(dirname "$0")"

# ------------------------------------------------------------
# NVIDIA + Wayland
# ------------------------------------------------------------

if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v nvidia-smi >/dev/null 2>&1; then

    DRIVER="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n 1 | tr -d ' ')"

    if [ -n "$DRIVER" ]; then

        MAJOR="${DRIVER%%.*}"

        echo "=========================================="
        echo " AnycubicSlicerNext Linux Compatibility"
        echo "=========================================="
        echo "GPU     : NVIDIA"
        echo "Driver  : $DRIVER"
        echo "Session : Wayland"

        if [ "$MAJOR" -gt 555 ] 2>/dev/null; then

            echo "Mode    : Zink"
            echo

            export __GLX_VENDOR_LIBRARY_NAME=mesa
            export MESA_LOADER_DRIVER_OVERRIDE=zink
            export GALLIUM_DRIVER=zink
            export WEBKIT_DISABLE_DMABUF_RENDERER=1

            if [ -f /usr/share/glvnd/egl_vendor.d/50_mesa.json ]; then
                export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
            fi

        else

            echo "Mode    : Native NVIDIA"
            echo

        fi
    fi

else

    echo "=========================================="
    echo " AnycubicSlicerNext"
    echo "=========================================="
    echo "Session : ${XDG_SESSION_TYPE:-unknown}"
    echo "Mode    : Native graphics stack"
    echo

fi

# ------------------------------------------------------------
# WebKit compatibility
# ------------------------------------------------------------

export WEBKIT_DISABLE_DMABUF_RENDERER=1

# ------------------------------------------------------------
# Start original application
# ------------------------------------------------------------

exec "$APPDIR/AppRun.original" "$@"
LAUNCHER

chmod +x "$APPDIR/AppRun"

# ============================================================
# Validate launcher
# ============================================================

if ! bash -n "$APPDIR/AppRun"; then
    echo
    echo "ERROR: Generated AppRun has invalid shell syntax."
    echo
    exit 1
fi

# ============================================================
# Determine version
# ============================================================

FILENAME="$(basename "$SOURCE")"

VERSION="$(printf '%s\n' "$FILENAME" | \
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' | \
    head -n 1 || true)"

if [[ -z "$VERSION" ]]; then
    VERSION="custom"
fi

OUTPUT="$SCRIPT_DIR/AnycubicSlicerNext-${VERSION}-linux-x86_64-linuxfix.AppImage"

rm -f "$OUTPUT"

# ============================================================
# Build
# ============================================================

echo "[4/5] Building LinuxFix AppImage..."

cd "$WORK_DIR"

ARCH=x86_64 "$APPIMAGETOOL" \
    --no-appstream \
    "$APPDIR" \
    "$OUTPUT"

# ============================================================
# Verify
# ============================================================

echo "[5/5] Verifying result..."

if [[ ! -f "$OUTPUT" ]]; then
    echo
    echo "ERROR: Output AppImage was not created."
    echo
    exit 1
fi

chmod +x "$OUTPUT"

FILE_TYPE="$(file "$OUTPUT")"

if ! printf '%s' "$FILE_TYPE" | grep -qi "AppImage\|ELF"; then
    echo
    echo "WARNING: Output file does not look like an AppImage:"
    echo "$FILE_TYPE"
    echo
fi

echo
echo "============================================================"
echo " SUCCESS"
echo "============================================================"
echo
echo "Created:"
echo
echo "  $OUTPUT"
echo
echo "Size:"
du -h "$OUTPUT" | cut -f1
echo
echo "Start it with:"
echo
echo "  ./$(basename "$OUTPUT")"
echo
echo "============================================================"
echo
