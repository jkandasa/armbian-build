# RK3128 SoC and board

The SoC is a Rockchip RK3128.
The PCB marking is MXQ-EP-68.
The model string is `RK3128 MXQ-EP-68`.
The compatible string is `rockchip,rk3128-box`.

## CPU and GPU

The CPU has four Cortex-A7 cores.
The CPU is 32-bit only.
The instruction set is ARMv7-A with NEON and VFPv4.
The CPU has no AArch64 mode.
The images are `armhf`.
The CPU clock range is 216 MHz to 1.2 GHz.
The GPU is a Mali-400 MP2.
The GPU driver is `lima`.
The GPU clock range is 200 MHz to 480 MHz.
The SoC has no TSADC.
The board has no thermal sensor.

## Memory and power

The board has 1 GiB LPDDR2 at 0x60000000.
The board has 4 GB eMMC.
The eMMC has two 4 MiB boot partitions.
PWM regulators supply the CPU and the GPU.

| Regulator | Source | Rail          | Voltage          |
| --------- | ------ | ------------- | ---------------- |
| vdd_arm   | PWM1   | CPU           | 1.05 V to 1.36 V |
| vdd_log   | PWM2   | Logic and GPU | 1.05 V to 1.30 V |

The PWM duty is inverted.
The factory U-Boot sets vdd_arm to 1.25 V at 36 % duty.
The regulators cannot go below 1.05 V.
The device tree raises the CPU OPPs 216 MHz to 696 MHz to 1.05 V.
The device tree raises the GPU 200 MHz OPP to 1.05 V.
Without that change, cpufreq and devfreq drop those OPPs.

## Boot

The boot ROM loads the ID block from sector 64.
The ID block holds the DDR init blob and the miniloader.
The miniloader loads `uboot.img` to 0x60000000.
U-Boot runs in secure mode.
The board has no SPL and no trust OS.
The factory miniloader is version 2.33.
That miniloader is in eMMC boot0.
That miniloader tries the SD card first.

| Sector | Offset | Content                                            |
| ------ | ------ | -------------------------------------------------- |
| 64     | 32 KiB | `idbloader.bin`: DDR blob v2.06 + miniloader v2.40 |
| 8192   | 4 MiB  | `uboot.img`                                        |
| 16384  | 8 MiB  | `uboot.img` copy                                   |
| 24576  | 12 MiB | 4 MiB of zeros, removes a stale trust OS           |
| 32768  | 16 MiB | Root partition                                     |

The factory partitions are in the PARM block at sector 0.
Values are 512-byte sectors.

| Name           | Offset   | Size     |
| -------------- | -------- | -------- |
| uboot          | 0x2000   | 0x2000   |
| trust          | 0x4000   | 0x2000   |
| misc           | 0x6000   | 0x2000   |
| resource       | 0x8000   | 0x8000   |
| kernel         | 0x10000  | 0x6000   |
| boot           | 0x16000  | 0x6000   |
| recovery       | 0x1C000  | 0x10000  |
| backup         | 0x2C000  | 0x20000  |
| cache          | 0x4C000  | 0x40000  |
| metadata       | 0x8C000  | 0x8000   |
| kpanic         | 0x94000  | 0x2000   |
| system         | 0x96000  | 0x400000 |
| radical_update | 0x496000 | 0x20000  |
| userdata       | 0x4B6000 | grow     |

## Storage

The SD card is `sdmmc` at 0x10214000.
The SDIO radio is `sdio` at 0x10218000.
The eMMC is `emmc` at 0x1021c000.
U-Boot names the eMMC `mmc 0` and the SD card `mmc 1`.
Linux names the SD card `mmcblk0` and the eMMC `mmcblk1`.
The SD bus width is 4 bits.
The SD CMD pin is GPIO1_B7.
GPIO1_B6 enables the SD power, active high.
The eMMC bus width is 8 bits.
The eMMC is MMC 4.5.
Linux runs the eMMC at 50 MHz in high-speed mode.
The read speed is about 40 MB/s.
U-Boot runs the eMMC at 25 MHz.
At 50 MHz, large U-Boot file loads get read errors.

## Ethernet

Ethernet uses the GMAC at 0x2008c000.
The PHY is a TI DP83848 at MDIO address 1.
The PHY mode is RMII at 100 Mb/s.
The SoC drives the 50 MHz RMII clock from CPLL.
The transmit delay is 0x30.
The receive delay is 0x10.
GPIO2_D0 is the PHY reset, active low.
The PHY answers on MDIO only after the RMII clock runs for 167 ms.
The MDIO bus resets the PHY and waits 200 ms before the scan.
The Linux interface name is `end0`.

## Wi-Fi

The radio chip is an iComm SSV6020C0.
The SDIO identity is 5653:2060.
The radio is 2.4 GHz 802.11n.
GPIO0_D6 enables the radio power, active high.
GPIO0_A2 is the radio reset, active low.
GPIO1_A2 is SDIO D1.
GPIO1_A2 is not a power hold.
Do not claim GPIO1_A2 with `gpio-poweroff` or a hog.
The Linux module is `ssv6158`.
The firmware files are `ssv6020-sw.bin` and `ssv6158-wifi.cfg`.
The crystal is 24 MHz.

## Video and audio

HDMI uses the Innosilicon HDMI transmitter.
HDMI audio uses `i2s_8ch` at 0x10200000.
The HDMI sound card name is `HDMI`.
The S/PDIF output uses `spdif` at 0x10204000.
The S/PDIF output is optical.
The S/PDIF sound card name is `SPDIF`.
The AV jack carries CVBS video and analog audio.
Mainline has no RK3128 TV encoder driver.
Mainline has no RK3128 audio codec driver.

## USB

The board has one USB host port on the EHCI and OHCI controllers.
The board has one USB OTG port on the DWC2 controller.
GPIO3_C4 enables the host VBUS.
GPIO3_C1 enables the OTG VBUS.

## Serial port

UART2 is the debug console at 115200 8N1.
UART2 TX is GPIO1_C2.
UART2 RX is GPIO1_C3.
These pins are also SD D0 and D1.
U-Boot muxes the pins to SD only while an MMC command runs.
Linux gives the pins to the SD card.
Linux keeps UART2 disabled.
The Linux console is on HDMI (`tty1`).
The image has no serial getty.
A connected adapter TX wire breaks 4-bit SD.
U-Boot then falls back to 1-bit SD.
Disconnect the adapter TX wire for a normal boot.

## Other pins

| Pin      | Role                                    |
| -------- | --------------------------------------- |
| GPIO0_B0 | Power LED, active low                   |
| GPIO0_D2 | Status LED, active high, heartbeat      |
| GPIO0_A5 | Power key, active low                   |
| GPIO3_D2 | Infrared receiver, active low           |
| GPIO3_C4 | USB host VBUS, active low               |
| GPIO3_C1 | USB OTG VBUS, active low                |
| GPIO1_A3 | AV amplifier enable, unused in Linux    |

The infrared receiver uses the `rc-empty` map.
The factory remotes use NEC user codes 0xfe01, 0xff00, 0x1dcc, and 0x4040.
