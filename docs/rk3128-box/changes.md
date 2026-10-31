# RK3128 source changes

The board id is `rk3128-box`.
The family is `rockchip`.
`BOOT_SOC` is `rk3128`.
Kernel targets are `current` and `edge`.
Build a headless image with this command.

```bash
./compile.sh build BOARD=rk3128-box BRANCH=current BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie
```

Use `BRANCH=current` for the 6.18 longterm kernel.
Use `BRANCH=edge` for the 7.3 stable kernel.
Edge uses only kernel.org stable releases, not mainline releases or release candidates.

## Files

| File                                                                                    | Role                                   |
| --------------------------------------------------------------------------------------- | -------------------------------------- |
| `config/boards/rk3128-box.tvb`                                                          | Board entry, Wi-Fi extension, console  |
| `config/sources/families/rockchip.conf`                                                 | rk3128 boot chain and CPU limits       |
| `config/bootscripts/boot-rk3128.cmd`                                                    | Boot script                            |
| `config/bootenv/rk3128.txt`                                                             | Default `armbianEnv.txt`               |
| `config/kernel/linux-rockchip-current.config`                                           | Enables `CONFIG_CLK_RK312X`            |
| `config/kernel/linux-rockchip-edge.config`                                              | Enables `CONFIG_CLK_RK312X`            |
| `extensions/ssv6158.sh`                                                                 | Build and install `ssv6158`            |
| `patch/misc/ssv6158/0001-port-to-linux-6.18.patch`                                      | mac80211 and kernel API port           |
| `patch/misc/ssv6158/0002-build-in-kernel-tree.patch`                                    | In-tree Makefile and Kconfig           |
| `patch/misc/ssv6158/0003-use-strscpy.patch`                                             | Replace `strncpy` for Linux 7.3        |
| `patch/misc/ssv6158/0004-disallow-stack-dma-buffers.patch`                              | No stack buffers for SDIO I/O          |
| `patch/kernel/archive/rockchip-6.18/dt/rk3128-box.dts`                                  | Kernel 6.18 board tree                 |
| `patch/kernel/archive/rockchip-7.3/dt/rk3128-box.dts`                                   | Kernel 7.3 board tree                  |
| `patch/kernel/archive/rockchip-6.18/drm-rockchip-inno-hdmi-add-audio-support.patch`     | HDMI audio, 6.18 driver                |
| `patch/kernel/archive/rockchip-7.3/drm-bridge-inno-hdmi-add-audio-support.patch`        | HDMI audio, 7.3 bridge driver          |
| `patch/u-boot/v2026.10/defconfig/rk3128-box_defconfig`                                  | U-Boot defconfig                       |
| `patch/u-boot/v2026.10/dt_upstream_rockchip_arm/rk3128-box.dts`                         | U-Boot board tree                      |
| `patch/u-boot/v2026.10/0000.patching_config.yaml`                                       | Copies 32-bit Rockchip trees           |
| `patch/u-boot/v2026.10/board_rk3128-box/arm-rockchip-rk3128-start-system-timer.patch`   | Starts a stopped arch timer            |
| `patch/u-boot/v2026.10/board_rk3128-box/clk-rockchip-rk3128-set-sd-and-emmc-card-clocks.patch` | SD and eMMC card clocks        |
| `patch/u-boot/v2026.10/board_rk3128-box/mmc-dw-rk3128-share-sd-pins-with-uart2.patch`   | MMC clock gates and shared pins        |

The kernel trees are identical.
Keep all copies identical.

The board sets `BSPFREEZE` to `yes` by default.
The image then holds the packages that the build made.
The repository has packages with the same names and no RK3128 support.
`BSPFREEZE=no` on the command line builds an image without the hold.

The board sets `SERIALCON="tty1"`.
That value skips the serial getty.
Linux keeps UART2 disabled.
A `ttyS2` getty waits 90 seconds for a device that never appears.

## Boot chain

`rockchip.conf` builds `idbloader.bin` from the rkbin DDR blob and miniloader.
The DDR blob is `rk31/rk3128_ddr_300MHz_v2.06.bin`.
The miniloader is `rk31/rk312x_miniloader_v2.40.bin`.
`loaderimage` packs `u-boot-dtb.bin` into `uboot.img` at 0x60000000.
`uboot_custom_postprocess()` runs these commands.

```bash
tools/mkimage -n rk3128 -T rksd -d rk3128_ddr_300MHz_v2.06.bin idbloader.bin
cat rk312x_miniloader_v2.40.bin >> idbloader.bin
loaderimage --pack --uboot u-boot-dtb.bin uboot.img 0x60000000
```

`write_uboot_platform()` writes U-Boot at 4 MiB and 8 MiB.
`write_uboot_platform()` zeros 12 MiB to 16 MiB.
The root partition starts at 16 MiB (`OFFSET=16`).
`rockchip.conf` limits the CPU to 216 MHz to 1.2 GHz for rk3128.

## U-Boot

The U-Boot version is v2026.10.
U-Boot builds rk3128 trees from the Linux device trees (`OF_UPSTREAM`).
`0000.patching_config.yaml` copies `dt_upstream_rockchip_arm` to `dts/upstream/src/arm/rockchip`.
The defconfig selects `rockchip/rk3128-box`.
The U-Boot aliases are `mmc0 = &emmc` and `mmc1 = &sdmmc`.
The eMMC node has no pinctrl.
The loader sets the eMMC pins.
An eMMC pinctrl makes the voltage select fail.
The eMMC runs at 25 MHz in default-speed mode.
The SD card runs at 25 MHz.
Both hosts use FIFO mode.
The SD node sets `rockchip,sd-uart-shared-pins`.

The timer patch starts the system timer only when the arch counter is stopped.
A stopped counter makes `udelay()` hang.
An unconditional start breaks console input.
The clock patch adds `set_rate` for `SCLK_SDMMC`, `HCLK_SDMMC`, and `SCLK_EMMC`.
The clock patch limits the divider to 64.
The MMC patch ungates the MMC clocks before the probe.
The MMC patch muxes GPIO1_C2 and GPIO1_C3 to SD for each command.
The MMC patch waits for the UART to finish its last bits.
The MMC patch muxes the pins back to UART2 after each command.

## Kernel device tree

The MDIO node holds the PHY reset on GPIO2_D0.
The reset delay is 10 ms.
The post-reset delay is 200 ms.
The PHY node has no reset GPIO.
The SD node sets the default sample phase to 90 at 50 MHz.
The SDIO node uses `mmc-pwrseq-simple` with the GPIO0_A2 reset.
The HDMI sound card links `i2s_8ch` to `hdmi` at 256 fs.
The S/PDIF sound card links `spdif` to `linux,spdif-dit`.
The tree enables the watchdog, the power key, and the infrared receiver.

## HDMI audio

The 6.18 patch registers the codec with `drm_connector_hdmi_audio_init`.
The 7.3 patch sets `DRM_BRIDGE_OP_HDMI_AUDIO` and the bridge audio callbacks.
In 7.3 the HDMI driver is a DRM bridge.
Both patches program the I2S input, the sample rate, and the N value.
Both patches send the audio infoframe.
Both patches restore the audio setup after a mode set.
The supported rates are 32 kHz to 192 kHz.
The maximum channel count is 8.

## Wi-Fi driver

The in-tree `ssv6051` driver does not support SSV6020.
The `ssv6x5x` driver does not support SSV6020.
The extension copies the pinned driver `a2afa9d80568895edd8875841137103801b51859`.
The extension builds the driver in the kernel tree as a module (`CONFIG_SSV6158=m`).
The source is `https://github.com/wltechblog/wifi-ssv6158`.
The pin keeps the kernel artifact hash stable.
The patches port the driver to the kernel 6.18 and 7.3 APIs.
The patches remove the exported symbols.
Those symbols clash with the in-tree `ssv6051` driver.
The build stops when the Kconfig line is missing.
The build stops when the Makefile line is missing.
The image build stops when `ssv6158.ko` is absent.
The SDIO alias loads `ssv6158` at boot.
The driver used stack buffers for SDIO register I/O.
With `CONFIG_VMAP_STACK`, this corrupted memory on kernel 7.x.
The 7.x edge images froze when `ssv6158` loaded.
Patch 0004 sets `CONFIG_MMC_DISALLOW_STACK`.
The driver then uses buffers in its allocated state.
The extension downloads `ssv6020-sw.bin` from the Radxa Allwinner BSP.
The extension checks the firmware SHA-256.

## Boot status

The SD card image boots.
The eMMC-only boot works on kernel 6.18.58.
The boot takes about 23 seconds to `multi-user.target`.
Ethernet comes up as `end0` after a cold boot.
`wlan0` associates with `ssv6158` on kernel 6.18.
HDMI video and HDMI audio work on kernel 6.18.
The 7.2.12 edge image boots, scans Wi-Fi, and passes 6 reboots.
Edge now uses kernel 7.3.1.
Kernel 7.3.1-edge boots, connects Wi-Fi, and plays HDMI audio on both channels.
Kernel 7.3.1-edge passes at least 5 reboots and 30 minutes idle.
S/PDIF output still needs a test.

## Known log messages

These kernel messages appear at each boot.
They do not affect the board.

| Message                                              | Cause                                          |
| ---------------------------------------------------- | ---------------------------------------------- |
| `Too many timer definitions for 'rk_timer'`          | The SoC tree lists more timers than the driver uses |
| `/cpus/cpu@f00 missing clock-frequency property`     | The upstream SoC tree omits the property       |
| `of_i2c: modalias failure on /hdmi@20034000/ports`   | The HDMI DDC bus scans the HDMI node children  |
| `Unsupported infoframe type: 131`                    | The 6.18 HDMI driver has no SPD infoframe      |
| `IPv6: MLD: clamping QRV from 1 to 2!`               | The router sends a low MLD robustness value    |
| `pixel format with alpha exposed but blend mode not setup` | The VOP planes set no blend mode         |
| `supply vusb_d not found, using dummy regulator`     | The board tree has no USB PHY supplies         |
| `No valid TOPs array specified`                      | The watchdog uses the default timeout table    |
| `using zero-initialized flat cache`                  | The 7.3 I2S regmap has no register defaults    |
