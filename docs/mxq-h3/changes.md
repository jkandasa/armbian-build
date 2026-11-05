# MXQ H3 source changes

The board id is `mxq-h3`.
The family is `sun8i`.
Kernel targets are `current` and `edge`.
Build a headless image with this command.

```bash
./compile.sh build BOARD=mxq-h3 BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no KERNEL_BTF=no RELEASE=trixie
```

Use `BRANCH=current` for the 6.18 longterm kernel.
The edge branch builds the 7.3 stable kernel.
The branch starts at `upstream/main`.
It has no changes from the rk3128 or ik316 branches, except the Wi-Fi extension.

## Files

| File                                                           | Role                             |
| -------------------------------------------------------------- | -------------------------------- |
| `config/boards/mxq-h3.tvb`                                     | Board entry, Wi-Fi, package hold |
| `packages/bsp/mxq-h3/mxq-h3-wifi-led`                          | Blue LED for the Wi-Fi IPv4 link |
| `packages/bsp/mxq-h3/mxq-h3-wifi-led.service`                  | Service for the Wi-Fi LED        |
| `extensions/ssv6x5x.sh`                                        | Build and install `ssv6x5x`      |
| `patch/misc/ssv6x5x/0001-replace-strncpy.patch`                | Replace `strncpy` with `strscpy` |
| `patch/kernel/archive/sunxi-6.18/dt_32/sun8i-h3-mxq.dts`       | Kernel 6.18 board tree           |
| `patch/kernel/archive/sunxi-7.3/dt_32/sun8i-h3-mxq.dts`        | Kernel 7.3 board tree            |

The two kernel trees are identical.
Keep both copies identical.

The Wi-Fi extension and its patch are copies from the ik316 branch.
Keep both copies identical.

The board sets `BSPFREEZE` to `yes` by default.
The image then holds the packages that the build made.
The repository has packages with the same names and no MXQ H3 device tree.
`BSPFREEZE=no` on the command line builds an image without the hold.

## U-Boot

The board uses U-Boot v2024.01 with the `u-boot-sunxi` patch set.
The defconfig is `orangepi_pc_plus_defconfig`.
U-Boot uses the Orange Pi PC Plus tree.
Linux gets `sun8i-h3-mxq.dtb` from `armbianEnv.txt`.

The Orange Pi PC Plus has the same SD, eMMC, Ethernet, and LED pins.
U-Boot drives PL2 high for USB VBUS.
U-Boot probes an SY8106A regulator on PL0 and PL1.
The board has no SY8106A, so U-Boot keeps the CPU at 408 MHz.
Linux then sets the CPU clock.

Two patches in `u-boot-sunxi` are important for this board:

- `allwinner-h3-set-safe-axi_apb-clock-dividers`: AXI /4, ATB /4, and a wait for the PLL1 lock
- `allwinner-h3-fix-pll1-setup-to-never-use-dividers`: no M divider in PLL1

Linux keeps the AXI and ATB dividers from U-Boot.
Mainline U-Boot sets AXI /3 and ATB /2.
At 1008 MHz that gives AXI 336 MHz and ATB 504 MHz.
`CPUX_AXI_CFG` reads `0x00020203` with the patched U-Boot.

U-Boot v2026.07 did not boot this board in the tests.
The `v2026.07-sunxi` patch set does not have the two clock patches.
The tests also used warm reboots from another system, so the cause is not proven.
Test v2026.07 again with cold starts only.

## Kernel tree

The tree includes `sun8i-h3.dtsi`.
The tree takes these parts from the Sunvell R69 tree:

- the Wi-Fi power on PL7 and the Wi-Fi reset on PL0
- the LED pins PA15 and PL10
- the eMMC pin drive of 40 mA

The tree adds these parts:

- the `wifi@1` node with host-wake on PA11
- the analog codec and the HDMI sound card
- USB EHCI and OHCI 2 and 3
- USB0 in host mode without a VBUS regulator
- both LEDs active low: red for power, blue for the Wi-Fi link

The tree has no CPU regulator.
The tree deletes the OPPs from 1104 MHz to 1368 MHz.
The stock kernel also stops at 1008 MHz.

The tree replaces the CPU cooling maps.
The old maps use cooling states 0 to 8 of the full table.
cpufreq now has 5 states, from 1008 MHz to 480 MHz.

| Trip               | Limit             |
| ------------------ | ----------------- |
| `cpu_very_hot_pre` | 960 to 816 MHz    |
| `cpu_very_hot`     | 648 MHz and lower |

The trips below `cpu_very_hot_pre` limited the CPU above 1008 MHz only.
The tree deletes them.

## Wi-Fi driver

The extension builds the pinned driver `cdhigh/armbian_sv6256p` at `43c2ede238b39ba3abb1129323a998495c6b8be9`.
The pin keeps the kernel artifact hash stable.
The driver builds on 32-bit ARM without changes.
The firmware comes from the `armbian-firmware` package.
The image loads `ssv6x5x` at boot from `/etc/modules-load.d/ssv6x5x.conf`.

## Build notes

Do not set `CPUMAX` in the board file.
The last line of `sun8i.conf` is `[[ -z $CPUMAX ]] && CPUMAX=1400000`.
That line returns 1 when `CPUMAX` is set.
The build then stops with an error in `main-config.sh`.
The kernel tree limits the CPU clock instead.

Set `KERNEL_BTF=no` on a host with less than 8 GiB RAM.

Do not set `BOOTCONFIG` on the command line.
The board file sets `BOOTCONFIG` again after the command line.
The BTF step stops the build on such a host.
