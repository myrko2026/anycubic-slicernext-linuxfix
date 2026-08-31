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
#
# IMPORTANT:
#   This script must NOT be run as root.
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

SOURCE="${1:-}"

# ============================================================
# Helper functions
# ============================================================

print_error() {
    echo
    echo "ERROR: $1"
    echo
}

# ============================================================
# Root check
# ============================================================

if [[ "${EUID}" -eq 0 ]]; then

    print_error "This script must NOT be run as root."

    echo "Please run it as your normal user:"
    echo
    echo "  ./build.sh AnycubicSlicer.AppImage"
    echo
    echo "Do NOT use:"
    echo
    echo "  sudo ./build.sh ..."
    echo

    exit 1
fi

# ============================================================
# Check argument
# ============================================================

if [[ -z "$SOURCE" ]]; then

    echo
    echo "============================================================"
    echo " AnycubicSlicerNext LinuxFix"
    echo "============================================================"
    echo
    echo "Usage:"
    echo
    echo "  ./build.sh AnycubicSlicer.AppImage"
    echo
    echo "Example:"
    echo
    echo "  ./build.sh AnycubicSlicerNext-1.3.9.4.AppImage"
    echo

    exit 1
fi

# ============================================================
# Resolve source path
# ============================================================

if ! SOURCE="$(realpath "$SOURCE" 2>/dev/null)"; then
    print_error "Could not determine the full path of the source AppImage."
    exit 1
fi

if [[ ! -f "$SOURCE" ]]; then

    print_error "AppImage not found:

  $SOURCE"

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
# Header
# ============================================================

echo
echo "============================================================"
echo " AnycubicSlicerNext LinuxFix Builder"
echo "============================================================"
echo
echo "This tool creates a LinuxFix AppImage for AnycubicSlicerNext."
echo
echo "Source:"
echo "  $SOURCE"
echo

# ============================================================
# Check architecture
# ============================================================

ARCH="$(uname -m)"

if [[ "$ARCH" != "x86_64" ]]; then

    print_error "This builder currently supports x86_64 only.

Detected architecture: $ARCH"

    exit 1
fi

echo "Architecture:"
echo "  x86_64"
echo

# ============================================================
# Check source AppImage permissions
# ============================================================

echo "Checking source AppImage permissions..."
echo

if [[ ! -r "$SOURCE" ]]; then

    print_error "The source AppImage is not readable:

  $SOURCE

Please check the file permissions and ownership."

    exit 1
fi

if [[ ! -x "$SOURCE" ]]; then

    echo "  Source AppImage is not executable."
    echo
    echo "  Adding executable permission:"
    echo
    echo "    chmod u+x \"$SOURCE\""
    echo

    if ! chmod u+x "$SOURCE"; then

        print_error "Could not make the source AppImage executable.

Please check the file ownership and permissions."

        exit 1
    fi

    if [[ ! -x "$SOURCE" ]]; then

        print_error "The executable permission could not be set."
        exit 1
    fi

    echo "  Executable permission added successfully."
    echo

else

    echo "  Source AppImage is executable."
    echo

fi

# ============================================================
# Check required commands
# ============================================================

echo "============================================================"
echo " Checking required software"
echo "============================================================"
echo

MISSING_PACKAGES=()

# ------------------------------------------------------------
# curl
# ------------------------------------------------------------

if command -v curl >/dev/null 2>&1; then

    echo "  [OK] curl"

else

    echo "  [MISSING] curl"
    MISSING_PACKAGES+=("curl")

fi

# ------------------------------------------------------------
# fuse3
# ------------------------------------------------------------

if command -v fusermount3 >/dev/null 2>&1; then

    echo "  [OK] fuse3"

else

    echo "  [MISSING] fuse3"
    MISSING_PACKAGES+=("fuse3")

fi

echo

# ============================================================
# Install missing packages
# ============================================================

if [[ "${#MISSING_PACKAGES[@]}" -gt 0 ]]; then

    echo "The following required packages are missing:"
    echo

    printf '  - %s\n' "${MISSING_PACKAGES[@]}"

    echo

    # --------------------------------------------------------
    # Check for apt
    # --------------------------------------------------------

    if ! command -v apt-get >/dev/null 2>&1; then

        echo "Automatic installation is currently only supported"
        echo "on Debian/Ubuntu-based Linux distributions."
        echo
        echo "The package manager 'apt' was not found."
        echo
        echo "Please install the following packages manually:"
        echo

        printf '  - %s\n' "${MISSING_PACKAGES[@]}"

        echo

        exit 1
    fi

    # --------------------------------------------------------
    # Check sudo
    # --------------------------------------------------------

    if ! command -v sudo >/dev/null 2>&1; then

        print_error "sudo is required to install missing packages.

Please install the following packages manually:

$(printf '  - %s\n' "${MISSING_PACKAGES[@]}")"

        exit 1
    fi

    echo "The missing packages can be installed automatically."
    echo
    echo "The following commands will be executed:"
    echo
    echo "  sudo apt update"
    echo "  sudo apt install ${MISSING_PACKAGES[*]}"
    echo
    echo "Your sudo password may be requested."
    echo

    read -r -p "Continue? [Y/n] " ANSWER

    case "${ANSWER:-Y}" in
        y|Y|yes|Yes|YES)
            ;;
        *)
            echo
            echo "Installation cancelled."
            echo
            exit 1
            ;;
    esac

    echo
    echo "Updating package information..."
    echo

    sudo apt update

    echo
    echo "Installing required packages..."
    echo

    sudo apt install -y "${MISSING_PACKAGES[@]}"

    echo
    echo "Package installation completed."
    echo

    # --------------------------------------------------------
    # Verify installation
    # --------------------------------------------------------

    INSTALL_FAILED=0

    if ! command -v curl >/dev/null 2>&1; then
        echo "  [ERROR] curl is still not available."
        INSTALL_FAILED=1
    else
        echo "  [OK] curl"
    fi

    if ! command -v fusermount3 >/dev/null 2>&1; then
        echo "  [ERROR] fuse3 / fusermount3 is still not available."
        INSTALL_FAILED=1
    else
        echo "  [OK] fuse3"
    fi

    echo

    if [[ "$INSTALL_FAILED" -ne 0 ]]; then

        print_error "One or more required packages could not be installed."

        exit 1
    fi

else

    echo "All required software is installed."
    echo

fi

# ============================================================
# Find or download appimagetool
# ============================================================

echo "============================================================"
echo " Checking appimagetool"
echo "============================================================"
echo

mkdir -p "$TOOLS_DIR"

if command -v appimagetool >/dev/null 2>&1; then

    APPIMAGETOOL="$(command -v appimagetool)"

    echo "  [OK] appimagetool found:"
    echo
    echo "      $APPIMAGETOOL"
    echo

elif [[ -x "$APPIMAGETOOL" ]]; then

    echo "  [OK] Local appimagetool found:"
    echo
    echo "      $APPIMAGETOOL"
    echo

else

    echo "  appimagetool was not found."
    echo
    echo "  Downloading the official appimagetool..."
    echo

    curl \
        --fail \
        --location \
        --progress-bar \
        "$APPIMAGETOOL_URL" \
        --output "$APPIMAGETOOL"

    chmod u+x "$APPIMAGETOOL"

    if [[ ! -x "$APPIMAGETOOL" ]]; then

        print_error "Could not make appimagetool executable."
        exit 1
    fi

    echo
    echo "  appimagetool downloaded successfully."
    echo

fi

# ============================================================
# Clean previous build
# ============================================================

echo "============================================================"
echo " Preparing build environment"
echo "============================================================"
echo

rm -rf "$WORK_DIR"

mkdir -p "$WORK_DIR"

echo "Working directory:"
echo "  $WORK_DIR"
echo

# ============================================================
# Extract original AppImage
# ============================================================

echo "[1/5] Extracting original AppImage..."
echo

cd "$WORK_DIR"

"$SOURCE" --appimage-extract >/dev/null

if [[ ! -d "$APPDIR" ]]; then

    print_error "AppImage extraction failed."
    exit 1
fi

echo "  Extraction successful."
echo

# ============================================================
# Check original AppRun
# ============================================================

echo "[2/5] Preparing AppRun..."
echo

if [[ ! -f "$APPDIR/AppRun" ]]; then

    print_error "Original AppImage does not contain AppRun."
    exit 1
fi

mv "$APPDIR/AppRun" "$APPDIR/AppRun.original"

echo "  Original AppRun preserved as:"
echo "    AppRun.original"
echo

# ============================================================
# Install compatibility launcher
# ============================================================

echo "[3/5] Installing Linux compatibility launcher..."
echo

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

    print_error "Generated AppRun has invalid shell syntax."
    exit 1
fi

echo "  Compatibility launcher installed."
echo

# ============================================================
# Determine version
# ============================================================

FILENAME="$(basename "$SOURCE")"

VERSION="$(
    printf '%s\n' "$FILENAME" |
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' |
        head -n 1 ||
        true
)"

if [[ -z "$VERSION" ]]; then
    VERSION="custom"
fi

OUTPUT="$SCRIPT_DIR/AnycubicSlicerNext-${VERSION}-linux-x86_64-linuxfix.AppImage"

rm -f "$OUTPUT"

# ============================================================
# Build AppImage
# ============================================================

echo "[4/5] Building LinuxFix AppImage..."
echo

cd "$WORK_DIR"

ARCH=x86_64 "$APPIMAGETOOL" \
    --no-appstream \
    "$APPDIR" \
    "$OUTPUT"

echo
echo "  AppImage build completed."
echo

# ============================================================
# Verify result
# ============================================================

echo "[5/5] Verifying result..."
echo

if [[ ! -f "$OUTPUT" ]]; then

    print_error "Output AppImage was not created."
    exit 1
fi

# ------------------------------------------------------------
# Ensure output is executable
# ------------------------------------------------------------

chmod u+x "$OUTPUT"

if [[ ! -x "$OUTPUT" ]]; then

    print_error "Generated AppImage is not executable."
    exit 1
fi

# ------------------------------------------------------------
# Check file type
# ------------------------------------------------------------

if command -v file >/dev/null 2>&1; then

    FILE_TYPE="$(file "$OUTPUT")"

    if ! printf '%s' "$FILE_TYPE" | grep -qi "AppImage\|ELF"; then

        echo "WARNING:"
        echo "The generated file does not look like a normal AppImage:"
        echo
        echo "  $FILE_TYPE"
        echo

    fi

fi

# ------------------------------------------------------------
# Check ownership
# ------------------------------------------------------------

CURRENT_USER="$(id -un)"
CURRENT_GROUP="$(id -gn)"

if [[ ! -O "$OUTPUT" ]]; then

    echo "WARNING:"
    echo "The generated AppImage is not owned by the current user."
    echo
    echo "Expected owner:"
    echo "  $CURRENT_USER:$CURRENT_GROUP"
    echo
    echo "Actual ownership:"
    ls -l "$OUTPUT"
    echo

else

    OWNER="$(stat -c '%U:%G' "$OUTPUT" 2>/dev/null || true)"

    echo "  Owner: $OWNER"

fi

# ============================================================
# Success
# ============================================================

echo
echo "============================================================"
echo " SUCCESS"
echo "============================================================"
echo
echo "LinuxFix AppImage created successfully."
echo
echo "Created:"
echo
echo "  $OUTPUT"
echo
echo "Size:"
du -h "$OUTPUT" | cut -f1
echo
echo "Owner:"
stat -c '%U:%G' "$OUTPUT" 2>/dev/null || ls -l "$OUTPUT"
echo
echo "The AppImage is executable and can be started with:"
echo
echo "  ./$(basename "$OUTPUT")"
echo
echo "Or simply double-click it in your file manager."
echo
echo "============================================================"
echo
