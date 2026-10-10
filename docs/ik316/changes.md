# IK316 source changes

The board id is `ik316`.
The family is `sun50iw9`.
Kernel targets are `current` and `edge`.
Build a headless image with this command.

```bash
./compile.sh build BOARD=ik316 BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie
```

Use `BRANCH=current` for the 6.18 kernel.
The edge branch builds the 7.2 kernel.

## Files

| File                                                                              | Role                            |
| --------------------------------------------------------------------------------- | ------------------------------- |
| `config/boards/ik316.tvb`                                                         | Board entry and Wi-Fi extension |
| `extensions/ssv6x5x.sh`                                                           | Build and install `ssv6x5x`     |
| `patch/misc/ssv6x5x/0001-replace-strncpy.patch`                                   | Keep the chip name `SSV6006C`   |
| `patch/kernel/archive/sunxi-6.18/dt_64/sun50i-h616-ik316.dts`                     | Kernel 6.18 board tree          |
| `patch/kernel/archive/sunxi-7.2/dt_64/sun50i-h616-ik316.dts`                      | Kernel 7.2 board tree           |
| `patch/u-boot/v2026.07-sunxi64/board_ik316/0001-add-ik316-dt-and-defconfig.patch` | U-Boot tree and DRAM            |
| `patch/u-boot/v2026.07-sunxi64/board_ik316/0002-h616-emmc-controller-setup.patch` | eMMC host registers             |

The two kernel trees are identical.
Keep both copies identical.

## U-Boot

The defconfig selects LPDDR3 at 720 MHz.
DCDC3 is 1200 mV.
The U-Boot aliases are `mmc0 = &mmc0` and `mmc1 = &mmc2`.
The boot command scans `mmc 1` for the eMMC.
The U-Boot tree does not enable the SDIO node.
The eMMC register writes run only for `SUNXI_MMC2_BASE`.
The SD host keeps the stock reset.
Register 0x08 receives the timeout value.
Register 0x50 receives 0xdeb.
Register 0x54 receives 3.

## Wi-Fi driver

The extension copies the pinned driver `43c2ede238b39ba3abb1129323a998495c6b8be9`.
The pin keeps the kernel artifact hash stable.
The patch replaces `strncpy` with `sized_strscpy`.
The short chip buffer size is the length plus one.
That size keeps the name `SSV6006C`.
The build stops when the Kconfig line is missing.
The build stops when the Makefile line is missing.
The image build stops when `ssv6x5x.ko` is absent.
The image loads `ssv6x5x` at boot.
The firmware package supplies both Wi-Fi files.

## Boot status

The SD card image boots.
Ethernet comes up as `end0`.
`wlan0` comes up with `ssv6x5x` on kernel 7.2.9-edge.
The eMMC root filesystem works when the SD bootloader starts it.
An eMMC-only boot still needs a test with this U-Boot.
