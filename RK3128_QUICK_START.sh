#!/bin/bash
# RK3128 Armbian Quick Build Script

echo "=========================================="
echo "RK3128 TV Box Armbian Build Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./RK3128_QUICK_START.sh"
    exit 1
fi

echo "Select build type:"
echo "1) Minimal (Console only)"
echo "2) Desktop with XFCE"
echo "3) Custom interactive build"
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo "Building minimal image..."
        ./compile.sh \
            BOARD=rk3128-box \
            BRANCH=current \
            RELEASE=bookworm \
            BUILD_MINIMAL=yes \
            BUILD_DESKTOP=no \
            KERNEL_CONFIGURE=no
        ;;
    2)
        echo "Building desktop image with XFCE..."
        ./compile.sh \
            BOARD=rk3128-box \
            BRANCH=current \
            RELEASE=bookworm \
            BUILD_DESKTOP=yes \
            DESKTOP_ENVIRONMENT=xfce \
            DESKTOP_ENVIRONMENT_CONFIG_NAME=config_base \
            KERNEL_CONFIGURE=no
        ;;
    3)
        echo "Starting interactive build..."
        ./compile.sh
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Build complete!"
echo "Image location: output/images/"
echo "=========================================="
