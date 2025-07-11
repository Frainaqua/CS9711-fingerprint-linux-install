#!/bin/bash

set -e

echo "====== Fingerprint Driver Auto Installer (libfprint-CS9711 + fprintd v1.94.4) ======"

# -------------------------------
# Step 1: Check for APT support
# -------------------------------
echo "[1/6] Checking for apt package manager..."
if ! command -v apt &>/dev/null; then
    echo "Error: apt package manager not found. This script supports only Debian/Ubuntu-based systems."
    exit 1
fi
echo "apt is available."

# -------------------------------
# Step 2: Check for required dependencies
# -------------------------------
echo
echo "[2/6] Verifying required dependencies..."

DEPENDENCIES=(
  git meson ninja-build build-essential pkg-config libglib2.0-dev
  libusb-1.0-0-dev libsystemd-dev libfprint-2-dev libdbus-1-dev
  libgudev-1.0-dev gettext libpam0g-dev libgirepository1.0-dev
  libpolkit-gobject-1-dev python3-dbusmock python3-dbus
  python3-pip python3-pydbus python3-gi-dev
)

MISSING=()
for pkg in "${DEPENDENCIES[@]}"; do
    dpkg -s "$pkg" &>/dev/null || MISSING+=("$pkg")
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "All required packages are installed."
else
    echo "The following dependencies are missing:"
    for m in "${MISSING[@]}"; do echo "  - $m"; done
    echo
    echo "Please install them manually using:"
    echo "sudo apt install ${MISSING[*]}"
    exit 1
fi

# -------------------------------
# Step 3: Clone libfprint-CS9711
# -------------------------------
echo
echo "[3/6] Cloning libfprint-CS9711..."

LIBFPRINT_DIR="libfprint-CS9711"
if [ -d "$LIBFPRINT_DIR" ]; then
    echo "Directory $LIBFPRINT_DIR already exists. Skipping clone."
else
    git clone https://github.com/ddlsmurf/libfprint-CS9711.git
fi
cd "$LIBFPRINT_DIR"

# -------------------------------
# Step 4: Build and install libfprint-CS9711
# -------------------------------
echo
echo "[4/6] Building and installing libfprint-CS9711..."

BUILD_DIR="build"
rm -rf "$BUILD_DIR"
meson setup "$BUILD_DIR"
meson compile -C "$BUILD_DIR"
sudo meson install -C "$BUILD_DIR"

cd ..

# -------------------------------
# Step 5: Download and extract fprintd v1.94.4
# -------------------------------
echo
echo "[5/6] Downloading and extracting fprintd v1.94.4..."

FPRINTD_URL="https://gitlab.freedesktop.org/libfprint/fprintd/-/archive/v1.94.4/fprintd-v1.94.4.tar.gz"
FPRINTD_TAR="fprintd-v1.94.4.tar.gz"
FPRINTD_DIR="fprintd-v1.94.4"

if [ -d "$FPRINTD_DIR" ]; then
    echo "Directory $FPRINTD_DIR already exists. Skipping download."
else
    curl -L -o "$FPRINTD_TAR" "$FPRINTD_URL"
    tar -xf "$FPRINTD_TAR"
fi
cd "$FPRINTD_DIR"

# -------------------------------
# Step 6: Build and install fprintd
# -------------------------------
echo
echo "[6/6] Building and installing fprintd..."

export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"

FPRINTD_BUILD="builddir"
rm -rf "$FPRINTD_BUILD"
meson setup "$FPRINTD_BUILD" --prefix=/usr -Dpam_modules_dir=/lib/security
ninja -C "$FPRINTD_BUILD"
sudo ninja -C "$FPRINTD_BUILD" install

echo
echo "All steps completed! fprintd has been built and installed successfully."
echo "Please refer to the README to verify and test fingerprint functionality manually."
