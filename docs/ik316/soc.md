# IK316 SoC and board

The SoC is an Allwinner H616.
The board name is IK316 eMCP.
The model string is `IK316 eMCP LPDDR3`.
The compatible string is `ik,ik316`.

## Memory and power

The board has 1 GiB LPDDR3.
The DRAM rank count is 2.
The DRAM geometry is 10 columns and 14 rows.
The board has 8 GiB eMMC.
The PMIC is an AXP313A on R_I2C address 0x36.
The stock name AXP1530 is this AXP313A.

| Regulator | Rail       | Voltage          |
| --------- | ---------- | ---------------- |
| DCDC1     | GPU        | 0.81 V to 1.16 V |
| DCDC2     | CPU        | 0.81 V to 1.16 V |
| DCDC3     | DRAM       | 1.2 V fixed      |
| ALDO1     | 1.8 V rail | 1.8 V            |
| DLDO1     | 3.3 V rail | 3.3 V            |

U-Boot sets DCDC3 to 1200 mV in the SPL.
The LPDDR3 training values come from the stock boot0.

| Symbol     | Value      |
| ---------- | ---------- |
| DRAM clock | 720 MHz    |
| DRAM type  | LPDDR3     |
| DX ODT     | 0x06060606 |
| DX DRI     | 0x0d0d0d0d |
| CA DRI     | 0x00000d0d |
| ODT enable | 1          |
| TPR0       | 0x0        |
| TPR1       | 0x80000000 |
| TPR2       | 0x0        |
| TPR6       | 0x2fa88080 |
| TPR10      | 0x002f3359 |
| TPR11      | 0xaa889967 |
| TPR12      | 0xeeee8979 |

## Storage and boot

The SD card is MMC0 at 0x04020000.
The SDIO radio is MMC1 at 0x04021000.
The eMMC is MMC2 at 0x04022000.
The eMMC bus width is 8 bits.
The SD card detect is PF6, active low.
The boot ROM tries the SD card first.
U-Boot names the eMMC block device `mmc 1`.

## Ethernet

Ethernet uses EMAC1 and the internal AC300 PHY.
The PHY mode is RMII.
The receive delay is 3100 ps.
The transmit delay is 700 ps.
The kernel device tree owns this node.
U-Boot v2026.10 has no EMAC1 node.

## Wi-Fi

The radio chip is an iComm SV6256P.
The package marking includes SV6256P.
The SDIO identity is 3030:3030.
The driver reports chip id SSV6006C0.
The driver short name is SSV6006C.
The Linux module is `ssv6x5x`.
The SDIO port uses 3.3 V for VMMC and VQMMC.
PG18 is the active-low reset.
PG10 feeds the 32 kHz clock.
PG15 is the host-wake interrupt.
Firmware files are `ssv6x5x-sw.bin` and `ssv6x5x-wifi.cfg`.

## Serial ports

The H616 has six UART controllers, UART0 to UART5.
This board enables UART0 and UART1.

| Port  | Pins                             | Role                      |
| ----- | -------------------------------- | ------------------------- |
| UART0 | PH0 TX, PH1 RX                   | Debug console, 115200     |
| UART1 | PG6 TX, PG7 RX, PG8 RTS, PG9 CTS | Enabled in the stock tree |

UART0 reaches the debug pads.
UART1 pins stay on the board.
This PCB has no second serial header.
UART2 to UART5 stay disabled.

## Other pins

PH5 is the power LED.
PH2 is the LAN LED.
PH3 is the activity LED.
PH9 is the green standby LED.
PH6 and PH7 drive the FD655 panel.
Leave PH6 and PH7 free.
PH8 enables USB1 VBUS.
PH10 is the infrared receiver.
USB0 works as a host.
The map uses the rc-beelink-gs1 table.
