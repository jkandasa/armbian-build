# MXQ H3 install and update

## Back up the stock Android

Back up the eMMC before you install Armbian.
Boot Armbian from the SD card first.
Run `lsblk`.
On this board the eMMC is the 7.3 GiB disk.
Confirm that name before the next command.
The example name is `/dev/mmcblk2`.

```bash
sudo dd if=/dev/mmcblk2 bs=4M status=progress | xz -T0 > /mnt/usb/mxq-h3-android.img.xz
```

Write the backup to a USB disk, not to the SD card that runs the system.
The backup needs about 2.3 GiB.

## Fresh install

Build the image on the host.

```bash
./compile.sh build BOARD=mxq-h3 BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no KERNEL_BTF=no RELEASE=trixie
```

Use `BRANCH=current` for the 6.18 kernel.
Set `CPUTHREADS` to the number of compile jobs.
The board sets `BSPFREEZE=yes`.
The image then holds the board packages.
Add `BSPFREEZE=no` to build an image without the hold.
The build needs 10 GiB free in `output/` and in `cache/`.

The image file is under `output/images/`.
The file name contains `Mxq-h3`.

Log in as `root`.
The initial password is `1234`.
Change that password at the first console login.
SSH is enabled.
The hostname is `mxq-h3`.
Ethernet uses DHCP.

## Write the image to an SD card

Find the SD card with `lsblk`.
Use the whole disk, for example `/dev/sdX`.
The write erases that whole disk.

```bash
xz -dc output/images/Armbian-*_Mxq-h3_*_minimal.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
```

Insert the card and power on the board.
The boot ROM tries the SD card first.
The stock Android on the eMMC stays in place.
Connect the debug pads at 115200 baud to see the boot log.

## Move the system to eMMC

Boot from the SD card.
Make the Android backup first.
Run `lsblk`.
Confirm the eMMC name.
The example name is `/dev/mmcblk2`.

```bash
sudo armbian-install --target /dev/mmcblk2 --boot emmc --fs ext4 --yes
```

The installer copies the root filesystem.
The installer writes U-Boot at 8 KiB on that disk.
Power off the board.
Remove the SD card.
Power on the board.
Use the new DHCP address.
Insert the SD card again when the box does not answer.

## Restore the stock Android

Boot Armbian from the SD card.
Write the backup to the eMMC.

```bash
xz -dc /mnt/usb/mxq-h3-android.img.xz | sudo dd of=/dev/mmcblk2 bs=4M conv=fsync status=progress
```

Power off the board.
Remove the SD card.
Power on the board.

## Package freeze

The board packages use the official Armbian package names.
The official kernel packages omit the MXQ H3 device tree and the `ssv6x5x` module.
`apt upgrade` can replace the board kernel.
The box then does not boot.

The board sets `BSPFREEZE=yes`.
The image build then runs `apt-mark hold` on each package that the build made.

These packages are frozen on an edge image.

| Package                       | Content                           |
| ----------------------------- | --------------------------------- |
| `linux-image-edge-sunxi`      | Kernel and `ssv6x5x` module       |
| `linux-dtb-edge-sunxi`        | Device trees with the MXQ H3 tree |
| `linux-u-boot-mxq-h3-edge`    | U-Boot files                      |
| `armbian-bsp-cli-mxq-h3-edge` | Board scripts and settings        |
| `armbian-firmware`            | Firmware with the Wi-Fi files     |
| `base-files`                  | Armbian base files                |

A current image freezes the `current` names of the first four packages.
The freeze does not hold the Debian packages.
`apt upgrade` updates those packages as usual.

Show the frozen packages.

```bash
apt-mark showhold
```

Do not use `Enable Armbian firmware upgrades` in `armbian-config`.
That entry removes the kernel hold.

## Upgrade the kernel on a running board

Read the running branch from `uname -r`.
A name with `edge` uses `BRANCH=edge`.
A name with `current` uses `BRANCH=current`.
Build the same branch on the host.

```bash
./compile.sh kernel BOARD=mxq-h3 BRANCH=edge KERNEL_CONFIGURE=no KERNEL_BTF=no
```

Copy both debs from `output/debs/` to the board.
One deb is `linux-image-<branch>-sunxi`.
The other deb is `linux-dtb-<branch>-sunxi`.
Use the `armhf` debs, not the `sunxi64` debs.
Use debs with the same version.

Install both packages on the board.

```bash
sudo apt-mark unhold linux-image-edge-sunxi linux-dtb-edge-sunxi
sudo dpkg -i linux-image-edge-sunxi_*.deb linux-dtb-edge-sunxi_*.deb
sudo apt-mark hold linux-image-edge-sunxi linux-dtb-edge-sunxi
sudo reboot
```

Replace `edge` with `current` on a current kernel.
Check the board after the reboot.

```bash
uname -r
lsmod | grep ssv6x5x
ip -br addr
```

## Upgrade U-Boot

A kernel upgrade leaves the bootloader in place.
Build U-Boot again only when the board U-Boot settings change.
The board file sets `BOOTBRANCH`, `BOOTPATCHDIR`, and `BOOTCONFIG`.
Do not move this board to U-Boot v2026.07 before a cold-start test passes.

```bash
./compile.sh uboot BOARD=mxq-h3 BRANCH=edge
```

Copy `linux-u-boot-mxq-h3-edge_*.deb` to the board.
Install that deb on the board.
The install copies the files to `/usr/lib/linux-u-boot-edge-mxq-h3/`.
The install does not write U-Boot to the eMMC.

```bash
sudo apt-mark unhold linux-u-boot-mxq-h3-edge
sudo dpkg -i linux-u-boot-mxq-h3-edge_*.deb
sudo apt-mark hold linux-u-boot-mxq-h3-edge
```

Back up the current U-Boot.

```bash
sudo dd if=/dev/mmcblk2 of=/root/uboot-backup.bin bs=1k skip=8 count=1016
```

Write U-Boot to the eMMC.

```bash
sudo bash -c 'source /usr/lib/u-boot/platform_install.sh && write_uboot_platform "$DIR" /dev/mmcblk2'
```

Compare the eMMC with the file before the reboot.
The two hashes must be the same.

```bash
f=/usr/lib/linux-u-boot-edge-mxq-h3/u-boot-sunxi-with-spl.bin
sha256sum < "$f"
sudo dd if=/dev/mmcblk2 bs=1k skip=8 status=none | head -c "$(stat -c %s "$f")" | sha256sum
```

If the hashes differ, restore the backup. Do not reboot.

```bash
sudo dd if=/root/uboot-backup.bin of=/dev/mmcblk2 bs=1k seek=8 conv=fsync
```

Replace `edge` with `current` on a current image.
A bad U-Boot on the eMMC stops the boot.
Keep an SD card with a working image near the board.
The boot ROM tries the SD card first, so that card recovers the board.

`FORCE_UBOOT_UPDATE=yes dpkg -i` does not write U-Boot.
The package `postinst` reads an empty value from `/etc/armbian-release`.
That empty value replaces `yes`.
Use `write_uboot_platform` as shown.

## LEDs on the h3_mxq_2026-11-03 image

The image of release `h3_mxq_2026-11-03` has the old LED settings.
In that image, the red LED is on and the blue LED is off.
Later images use red for power and blue for the Wi-Fi link.
Use this overlay to get the new LED settings without a new image.

```bash
cat > /tmp/mxq-h3-leds.dts <<'DTS'
/dts-v1/;
/plugin/;

/ {
	fragment@0 {
		target-path = "/leds/led-0";
		__overlay__ {
			label = "mxq-h3:blue:wifi";
			gpios = <&pio 0 15 1>;
			default-state = "off";
		};
	};

	fragment@1 {
		target-path = "/leds/led-1";
		__overlay__ {
			label = "mxq-h3:red:power";
			gpios = <&r_pio 0 10 1>;
			default-state = "on";
		};
	};
};
DTS
sudo armbian-add-overlay /tmp/mxq-h3-leds.dts
```

Install `mxq-h3-wifi-led` and `mxq-h3-wifi-led.service` from `packages/bsp/mxq-h3/`.
Put the script in `/usr/lib/mxq-h3/` and the unit in `/usr/lib/systemd/system/`.
Then run `sudo systemctl enable mxq-h3-wifi-led` and reboot.

## Wi-Fi SDIO clock

The Wi-Fi driver runs the SDIO bus at 50 MHz.
Use 25 MHz when the log shows SDIO errors such as `EILSEQ` or `-84`.
25 MHz limits Wi-Fi to about 50 Mbit/s.

```bash
echo "options ssv6x5x ssv6xxx_sdio_slow_clock=1" | sudo tee /etc/modprobe.d/ssv6x5x.conf
sudo reboot
```

Remove the file to go back to 50 MHz.

## First checks on the board

```bash
free -h
cat /sys/firmware/devicetree/base/model; echo
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
lsmod | grep ssv6x5x
nmcli dev wifi list
aplay -l
```

The memory is about 1 GiB.
The model is `MXQ H3 Q44`.
The highest CPU clock is 1008000 kHz.
`aplay -l` lists the analog codec and HDMI.
