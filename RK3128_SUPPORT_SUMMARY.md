# RK3128 Support for Armbian

## Overview
Added complete RK3128 SoC support to Armbian build system. RK3128 is a 32-bit quad-core Cortex-A7 processor similar to RK322x.

## Changes Made

### 1. Board Configuration
**File**: `config/boards/rk3128-box.tvb`
- Board definition for RK3128-based TV boxes
- Uses 32-bit Rockchip family configuration
- Kernel and U-Boot targets configured

### 2. Device Tree
**Files**:
- `patch/kernel/archive/rockchip-6.12/dt/rk3128-box.dts`
- `patch/kernel/archive/rockchip-6.17/dt/rk3128-box.dts`
- Hardware definition for RK3128 TV box variants

### 3. U-Boot Configuration
**Files**: `patch/u-boot/v2025.10/board_rk3128-box/`
- Board-specific patches for U-Boot v2025.10
- Configuration for RK3128 hardware initialization

### 4. Boot Environment
**Files**:
- `config/bootenv/rk3128.txt` - Boot environment variables
- `config/bootscripts/boot-rk3128.cmd` - Boot script for loading kernel/initrd

### 5. Binary Blobs
**Files**:
- `packages/blobs/rockchip/rk3128_ddr_300MHz_v2.08.bin` - DDR3 initialization (300MHz)
- `packages/blobs/rockchip/rk3128_tee.bin` - Trusted Execution Environment

### 6. Family Configuration
**File**: `config/sources/families/rockchip.conf`

#### Added Boot Configuration:
```bash
BOOT_SOC="rk3128"
BOOTSCRIPT="boot-rk3128.cmd:boot.cmd"
BOOTENV_FILE='rk3128.txt'
OVERLAY_PREFIX='rk3128'
BOOTBRANCH='tag:v2025.10-rc5'
BOOTPATCHDIR='v2025.10'
```

#### U-Boot Build Process:
- Uses proprietary DDR blob for reliable memory initialization
- Creates simple boot image: DDR blob (32KB) + U-boot binary (at offset 64 sectors)
- Target: `u-boot-rk3128-with-spl.bin`

#### Flash Layout:
- Writes to SD card at sector 1 (skips sector 0 to preserve MBR)
- 63 blocks (32KB each) zeroed for clean flash area
- U-Boot placed at 32KB offset

#### Special Features:
- Lima GPU driver support (via xorg-lima-serverflags extension)
- Similar architecture to RK322x for compatibility

## Build Command
```bash
./compile.sh BOARD=rk3128-box BRANCH=current BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=bookworm
```

## Technical Notes
- **Architecture**: 32-bit ARM (armhf)
- **CPU**: Quad-core Cortex-A7
- **Memory**: DDR3 support at 300MHz
- **Boot Method**: Rockchip proprietary blob-based initialization
- **Kernel Support**: 6.12 and 6.17 series
- **U-Boot**: v2025.10-rc5

## Status
✅ Configuration complete and ready for build testing
