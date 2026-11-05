# MXQ H3 SoC and board

The SoC is an Allwinner H3, `sun8iw7p1`.
The stock device tree also matches the H2+.
The SoC is under the heat sink.
The CPU is a quad-core Cortex-A7, 32-bit.
The GPU is a Mali-400 MP2.
The model string is `MXQ H3 Q44`.
The compatible string is `mxq,mxq-h3`.

The stock Android claims Android 13, `QuadCore-H64`, and 4K.
These claims are false.
The stock system is Android 7.0 with Linux 4.4.55.

## Memory and power

The board has 1 GiB DDR3L.
The RAM chips are 2 SK Hynix H5TC4G63 DDR3L chips, 4 Gbit each.
The board has 8 GiB eMMC, a Kioxia THGBMHG6C1LBAIL.
The board has no PMIC.

| Symbol     | Stock       | Armbian U-Boot |
| ---------- | ----------- | -------------- |
| DRAM type  | DDR3        | DDR3           |
| DRAM clock | 576 MHz     | 624 MHz        |
| ZQ         | 0x3b3bfb    | 0x3b3bfb       |
| ODT enable | 1           | 1              |

The 10 minute RAM stress test passes at 624 MHz.

## CPU clock and voltage

The stock kernel uses the `opp_l_table0` table.
That table runs from 480 MHz to 1008 MHz.
Every entry is 1.30 V.
So the stock firmware never changes the CPU voltage and never runs above 1008 MHz.

The stock device tree also has a `dvfs_table` node up to 1.2 GHz.
The CPU node does not use that node.

The stock kernel sends DVFS requests to the AR100 co-processor.
The AR100 firmware is `scp` in the boot package at 12 MiB.
That firmware can select 4 voltage levels with 2 pins.
The stock table uses one level only.

PL6 is not the CPU voltage control.
With PL6 as a GPIO regulator and OPPs up to 1.2 GHz, the kernel crashed under load.
The kernel tree has no CPU regulator and stops at 1008 MHz.

## SoC identity

| Check                         | Value        | Meaning            |
| ----------------------------- | ------------ | ------------------ |
| Chip ID, `VER_REG` bits 31:16 | `0x1680`     | H3 or H2+ die      |
| SID word 0, 0x01c14200        | `0x02c00081` | H3, not H2+        |
| CPU                           | 4 × Cortex-A7 r0p5 | H3 or H2+    |

Set bit 15 of `VER_REG` at 0x01c00024 to read the chip ID.
Clear bit 15 after the read.
The SID rule comes from linux-sunxi reports.
Remove the heat sink to read the marking for proof.

## Storage and boot

The SD card is MMC0.
The SD card bus width is 4 bits.
The SD card detect is PF6, active low.
The SDIO radio is MMC1.
The eMMC is MMC2.
The eMMC bus width is 8 bits.
The boot ROM tries the SD card first.
The stock boot0 is at 8 KiB on the eMMC.

## Ethernet

Ethernet is 10/100 Mbit/s.
Ethernet uses the EMAC and the internal H3 PHY.
The PHY mode is MII.
The magnetics are a PPT PM44-118P.

## Wi-Fi and Bluetooth

The radio chip is an iComm SV6256P.
The SDIO identity is 3030:3030.
The Linux module is `ssv6x5x`.
The stock module has the same name.
The firmware files are `ssv6x5x-sw.bin` and `ssv6x5x-wifi.cfg`.
The Armbian firmware file `ssv6x5x-sw.bin` is identical to the stock file.
The stock configuration sets a 24 MHz crystal.

The chip supports 2.4 GHz and 5 GHz.
The stock configuration disables 5 GHz with `hw_cap_5ghz = off`.
The Armbian configuration enables 5 GHz.
The board test connects on channel 36, 40 MHz wide, at MCS 7.

The driver starts the SDIO bus at 25 MHz.
After the firmware load, the driver sets the bus to 50 MHz.
The module parameter `ssv6xxx_sdio_slow_clock=1` keeps the bus at 25 MHz.

| SDIO clock | Download, 5 runs, Mbit/s     | Average |
| ---------- | ---------------------------- | ------- |
| 50 MHz     | 81.9, 31.1, 88.8, 14.2, 88.6 | 60.9    |
| 25 MHz     | 36.9, 47.9, 48.7, 49.0, 49.7 | 46.4    |
| 50 MHz     | 16.0, 56.0, 16.1, 88.2, 50.7 | 45.4    |

50 MHz gives the highest speed, but the speed changes between runs.
25 MHz limits the speed to about 50 Mbit/s, but the speed is stable.
The log shows no SDIO errors at 50 MHz.
The test used an internet download, so the speed changes can come from the network.

| Signal         | Pin  | Kernel use                      |
| -------------- | ---- | ------------------------------- |
| Wi-Fi power    | PL7  | `vcc-wifi` regulator            |
| Wi-Fi reset    | PL0  | `mmc-pwrseq-simple`, active low |
| Wi-Fi wake     | PA11 | Host-wake interrupt             |
| BT reset       | PL1  | Not used                        |
| BT wake        | PA12 | Not used                        |
| BT host-wake   | PL6  | Not used                        |
| BT UART        | UART1 | Not used                        |

The stock tree lists PL6 for the BT host-wake.
The stock tree also sets `bt_hostwake_enable` to 0.

## LEDs and IR

| LED     | Pin  | State in Linux |
| ------- | ---- | -------------- |
| Status  | PA15 | On             |
| Standby | PL10 | Off            |

The IR receiver uses the CIR on PL11.
The stock remote uses NEC.
The stock power key is code 0x1a at address 0xfb04.

## Audio and video

HDMI is on.
The stock tree disables HDCP and CEC.
HDMI audio uses I2S2.
The analog codec drives the AV jack.
The stock image also enables S/PDIF.

## USB

The stock tree lists 4 USB controllers.
USB0 is host mode.
The stock tree has no VBUS GPIO.
The kernel tree enables all 4 EHCI and OHCI pairs.

## Serial ports

The debug UART is UART0 on PA4 and PA5.
The speed is 115200 baud.
The pads are `RX TX GND`.

## Stock eMMC layout

The stock image is 7.28 GiB.
The table uses MBR with logical partitions.
The Allwinner partition table at 20 MiB supplies the names.

| Part | Name           | Size    | Content          |
| ---- | -------------- | ------- | ---------------- |
| 2    | `bootloader`   | 16 MiB  | FAT16            |
| 5    | `env`          | 16 MiB  | U-Boot variables |
| 6    | `boot`         | 32 MiB  | Android boot     |
| 7    | `system`       | 2 GiB   | ext4             |
| 8    | `verity_block` | 16 MiB  |                  |
| 9    | `misc`         | 16 MiB  |                  |
| 10   | `recovery`     | 32 MiB  | Android boot     |
| 11   | `private`      | 16 MiB  |                  |
| 12   | `alog`         | 64 MiB  |                  |
| 13   | `Reserve0`     | 16 MiB  | FAT              |
| 14   | `Reserve1`     | 32 MiB  |                  |
| 15   | `Reserve2`     | 16 MiB  |                  |
| 16   | `cache`        | 768 MiB | ext4             |
| 1    | `UDISK`        | 4.3 GiB | ext4, `/data`    |
