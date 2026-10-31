# IK316 source changes

The board id is `ik316`.
The family is `sun50iw9`.
Kernel targets are `current` and `edge`.
Build a headless image with this command.

```bash
./compile.sh build BOARD=ik316 BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie
```

Use `BRANCH=current` for the 6.18 longterm kernel.
The edge branch builds the 7.3 stable kernel.
Edge uses only kernel.org stable releases, not mainline releases or release candidates.

## Files

| File                                                                                  | Role                              |
| ------------------------------------------------------------------------------------- | --------------------------------- |
| `config/boards/ik316.tvb`                                                             | Board entry, Wi-Fi, package hold  |
| `extensions/ssv6x5x.sh`                                                               | Build and install `ssv6x5x`       |
| `patch/misc/ssv6x5x/0001-replace-strncpy.patch`                                       | Replace `strncpy` with `strscpy`  |
| `patch/kernel/archive/sunxi-6.18/dt_64/sun50i-h616-ik316.dts`                         | Kernel 6.18 board tree            |
| `patch/kernel/archive/sunxi-7.3/dt_64/sun50i-h616-ik316.dts`                          | Kernel 7.3 board tree             |
| `patch/u-boot/v2026.10-sunxi64/board_ik316/board-ik316-add-dt-and-defconfig.patch`    | U-Boot tree and DRAM              |
| `patch/u-boot/v2026.10-sunxi64/board_ik316/sunxi-mmc-h616-emmc-controller-setup.patch` | eMMC host registers              |

The three kernel trees are identical.
Keep all copies identical.

The board sets `BSPFREEZE` to `yes` by default.
The image then holds the packages that the build made.
The repository has packages with the same names and no IK316 device tree.
`BSPFREEZE=no` on the command line builds an image without the hold.

## U-Boot

The U-Boot version is v2026.10.
The defconfig selects LPDDR3 at 720 MHz.
DCDC3 is 1200 mV.
U-Boot has no Ethernet.
The U-Boot aliases are `mmc0 = &mmc0` and `mmc1 = &mmc2`.
The boot command scans `mmc 1` for the eMMC.
The U-Boot tree does not enable the SDIO node.

The eMMC patch name sorts after the family patches.
The family patch `mmc-increase-stabilization-delay-1ms-to-20ms` changes the same function.
The eMMC register writes run only for `SUNXI_MMC2_BASE`.
The SD host keeps the stock reset.

| Register | Name | Value        |
| -------- | ---- | ------------ |
| 0x08     | TMOUT | 0xffffffff  |
| 0x50     | DBGC | 0xdeb        |
| 0x54     | CSDC | 3            |

## Wi-Fi driver

The extension copies the pinned driver `43c2ede238b39ba3abb1129323a998495c6b8be9`.
The pin keeps the kernel artifact hash stable.
The patch replaces `strncpy` with `strscpy`.
The short chip buffer size is the length plus one.
That size keeps the name `SSV6006C`.
The build stops when the Kconfig line is missing.
The build stops when the Makefile line is missing.
The image build stops when `ssv6x5x.ko` is absent.
The image loads `ssv6x5x` at boot.
The firmware package supplies both Wi-Fi files.

## Boot status

The SD card image boots.
The eMMC-only boot works with the v2026.07 U-Boot and kernel 7.2.9-edge.
Ethernet comes up as `end0` at 100 Mb/s.
`wlan0` comes up with `ssv6x5x` on kernel 7.2.9-edge.
The eMMC runs at 50 MHz, 8 bits, DDR52.
The CPU scales from 480 MHz to 1.512 GHz.
Kernel 7.2.12-edge boots from the eMMC with the v2026.07 U-Boot.
`ssv6x5x` loads and Ethernet comes up on 7.2.12-edge.
The eMMC boot works with the v2026.10 U-Boot, TF-A lts-v2.14.11, and kernel 7.2.12-edge.
Kernel 6.18.58-current builds. It is not tested on the board.
Kernel 6.18.60-current and 7.3.1-edge build. They are not tested on the board.

## Known log messages

These kernel messages appear at each boot.
They do not affect Ethernet, Wi-Fi, or the eMMC.
The keymap module `rc-beelink-gs1` is in `/lib/modules`.

| Message                                              | Cause                                          |
| ---------------------------------------------------- | ---------------------------------------------- |
| `supply vcc-pX not found, using dummy regulator`     | The tree sets no pin bank supplies             |
| `IR keymap rc-beelink-gs1 not found`                 | The IR driver asks for the keymap at 1.1 s     |

The stock tree gives only the PC bank voltage, 1.8 V.
The other bank voltages are not known.
A wrong supply sets a wrong pin bias and can stop the eMMC or Wi-Fi.
Add the supplies only after a test on the board.
