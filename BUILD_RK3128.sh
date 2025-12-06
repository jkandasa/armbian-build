#!/bin/bash
# RK3128-box Armbian Build Script
# This script builds a minimal Armbian image for RK3128 TV boxes with SKHynix H9TP32A8JDBC eMCP

set -e

echo "=========================================="
echo "Building Armbian for RK3128-box"
echo "=========================================="
echo ""
echo "Hardware: RK3128 TV Box with SKHynix H9TP32A8JDBC eMCP"
echo "- CPU: RK3128 (Quad-core Cortex-A7)"
echo "- eMMC: H9TP32A8JDBC (auto-detected)"
echo "- LPDDR3: H9TP32A8JDBC (auto-detected)"
echo ""
echo "Build Configuration:"
echo "- Board: rk3128-box"
echo "- Branch: current (kernel 6.12.x)"
echo "- Release: bookworm (Debian 12)"
echo "- Type: Minimal console"
echo ""
echo "Estimated build time: 30-50 minutes"
echo ""
read -p "Press ENTER to start the build (or Ctrl+C to cancel)..."

cd "$(dirname "$0")"

./compile.sh \
  BOARD=rk3128-box \
  BRANCH=current \
  RELEASE=bookworm \
  BUILD_MINIMAL=yes \
  BUILD_DESKTOP=no \
  KERNEL_CONFIGURE=no \
  CLEAN_LEVEL=oldcache

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Your image is ready in:"
ls -lh output/images/Armbian_*_rk3128-box_*.img 2>/dev/null | tail -1
echo ""
echo "Next steps:"
echo "1. Flash to SD card:"
echo "   sudo dd if=output/images/Armbian_*.img of=/dev/sdX bs=4M status=progress conv=fsync"
echo ""
echo "2. Boot your RK3128 TV box from SD card"
echo ""
echo "3. Complete first-boot setup (root password, user creation)"
echo ""
