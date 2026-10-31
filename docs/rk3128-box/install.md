# RK3128 install and update

## Fresh install

Use an x86_64 or arm64 Linux host with Docker.
Get the build tree with the board files.

```bash
git clone https://github.com/armbian/build
cd build
```

Build the image on the host.

```bash
./compile.sh build BOARD=rk3128-box BRANCH=current BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie
```

Set `CPUTHREADS` to the number of compile jobs.
The default is one and a half times the host CPU count.
Use a positive integer.
The same option applies to the kernel command and the U-Boot command.

```bash
./compile.sh build BOARD=rk3128-box BRANCH=current BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie CPUTHREADS=18
```

Use `BRANCH=edge` for the 7.3 stable kernel.
The board sets `BSPFREEZE=yes`.
The image then holds the board packages.
Add `BSPFREEZE=no` to build an image without the hold.
The build needs 10 GiB free in `output/` and in `cache/`.
A newer 6.18 stable release can break the family patches.
Pin the kernel version in that case, for example `KERNELBRANCH='tag:v6.18.55'`.

The image file is under `output/images/`.
The file name contains `Rk3128-box`.

Log in as `root`.
The initial password is `1234`.
Change that password at the first console login.
SSH is enabled.
The hostname is `rk3128-box`.
Ethernet uses DHCP on `end0`.
The first login can print `Network connection timeout!`.
The login waits only 6 seconds for an address.
The network keeps trying in the background.

## Write the image to an SD card

Find the SD card with `lsblk`.
Use the whole disk, for example `/dev/sdX`.
The write erases that whole disk.

```bash
sudo dd if=output/images/Armbian-unofficial_*_Rk3128-box_*_minimal.img of=/dev/sdX bs=4M conv=fsync status=progress
```

Decompress an `.img.xz` image on the fly.

```bash
xz -dc Armbian_*_Rk3128-box_*.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
```

You can also flash from the build tree.

```bash
./compile.sh flash BOARD=rk3128-box CARD_DEVICE=/dev/sdX
```

Disconnect the serial adapter TX wire.
That wire breaks 4-bit SD.
Insert the card and power on the board.
The factory miniloader boots the SD card first.

## Move the system to eMMC

Boot from the SD card.
Run `lsblk`.
On this board the eMMC is the 3.6 GiB disk.
Confirm that name before the next command.
The example name is `/dev/mmcblk1`.

```bash
sudo armbian-install --target /dev/mmcblk1 --boot emmc --fs ext4 --yes
```

`armbian-install` without options opens the menu.
Select the eMMC install there.

The installer erases the factory Android system.
Keep a factory dump before this step.
The installer copies the root filesystem.
The installer writes U-Boot at 4 MiB and 8 MiB on that disk.
Power off the board.
Remove the SD card.
Power on the board.
Use the new DHCP address.
Insert the SD card again when the box does not answer.

Do not `dd` the image to the eMMC.
The root partition then keeps the image size.
The first-boot resize does not run.

## Package freeze

The board packages use the official Armbian package names.
The image uses `apt.armbian.com`.
The official packages omit the RK3128 device tree.
The official packages omit the HDMI audio patch and the SSV6020 driver.
`apt upgrade` can replace the board kernel.
The box then does not boot.

The board sets `BSPFREEZE=yes`.
The image build then runs `apt-mark hold` on each package that the build made.
These packages are frozen on a current image.

| Package                              | Content                               |
| ------------------------------------ | ------------------------------------- |
| `linux-image-current-rockchip`       | Kernel, HDMI audio, `ssv6158` module  |
| `linux-dtb-current-rockchip`         | Device trees with `rk3128-box.dtb`    |
| `linux-u-boot-rk3128-box-current`    | U-Boot files                          |
| `armbian-bsp-cli-rk3128-box-current` | Board scripts and settings            |
| `armbian-firmware`                   | Firmware files                        |
| `base-files`                         | Armbian base files                    |

An edge image freezes the `edge` names of the first four packages.
The freeze does not hold the Debian packages.
The freeze does not hold `armbian-config`.
`apt upgrade` updates those packages as usual.

Show the frozen packages.

```bash
apt-mark showhold
```

Images built before this change have no freeze.
Freeze the board packages on such a system.

```bash
sudo apt-mark hold linux-image-current-rockchip linux-dtb-current-rockchip linux-u-boot-rk3128-box-current armbian-bsp-cli-rk3128-box-current armbian-firmware base-files
```

Replace `current` with `edge` on an edge kernel.
`apt` does not upgrade, remove, or replace a frozen package.

## armbian-config options

`armbian-config` has two menu entries for the kernel packages.
System > Updates > `Disable Armbian firmware upgrades` holds the kernel image and the device tree.
That entry also holds the headers when they are installed.
That entry does not hold U-Boot or the BSP package.
System > Updates > `Enable Armbian firmware upgrades` removes that hold.
Do not use `Enable Armbian firmware upgrades` on this board.
The next `apt upgrade` then installs the official kernel without `rk3128-box.dtb`.
Do not use System > Kernel > `Use alternative kernels` on this board.
That entry installs a kernel from `apt.armbian.com`.
That kernel has no `rk3128-box.dtb`, and the box does not boot.
System > Storage > `Install the running system to internal media` is safe.
That entry is the same installer as `armbian-install`.

## Update a frozen package

Update a frozen package with a deb from this build tree.
Do not unfreeze the kernel, the device tree, U-Boot, or the BSP package for `apt upgrade`.
`apt upgrade` then installs the official package with the same name.

Use these steps for each update.

1. Build the new deb on the host.
2. Copy the deb to the board.
3. Unfreeze the package.
4. Install the deb with `dpkg -i`.
5. Freeze the package again.
6. Check the result with `apt-mark showhold`.

The next sections show the commands for the kernel and for U-Boot.

`armbian-firmware` and `base-files` can come from the Armbian repository.
Unfreeze them to get repository updates.

```bash
sudo apt-mark unhold armbian-firmware base-files
sudo apt update
sudo apt upgrade
sudo apt-mark hold armbian-firmware base-files
```

Check that `/lib/firmware/ssv6020-sw.bin` is present after a firmware update.
The Wi-Fi extension installs that file outside the firmware package.

## Upgrade the kernel on a running board

Read the running branch from `uname -r`.
A name with `edge` uses `BRANCH=edge`.
A name with `current` uses `BRANCH=current`.
Build the same branch on the host.

```bash
./compile.sh kernel BOARD=rk3128-box BRANCH=current KERNEL_CONFIGURE=no CPUTHREADS=18
```

Copy both debs from `output/debs/` to the board.
One deb is `linux-image-<branch>-rockchip`.
The other deb is `linux-dtb-<branch>-rockchip`.
Use debs with the same version.

Install both packages on the board.

```bash
sudo apt-mark unhold linux-image-current-rockchip linux-dtb-current-rockchip
sudo dpkg -i linux-image-current-rockchip_*.deb linux-dtb-current-rockchip_*.deb
sudo apt-mark hold linux-image-current-rockchip linux-dtb-current-rockchip
sudo reboot
```

Replace `current` with `edge` on an edge kernel.
The packages create `uInitrd`.
The packages point `/boot/zImage`, `/boot/uInitrd`, and `/boot/dtb` to the new kernel.

Check the board after the reboot.

```bash
uname -r
lsmod | grep ssv6158
aplay -l
ip -br addr
```

## Change between current and edge

Install the other branch with `dpkg -i`.
Reboot and check the board.
Remove the old branch.

```bash
sudo apt-mark unhold linux-image-current-rockchip linux-dtb-current-rockchip
sudo apt remove linux-image-current-rockchip linux-dtb-current-rockchip
sudo apt-mark hold linux-image-edge-rockchip linux-dtb-edge-rockchip
```

Swap `current` and `edge` for the other direction.
`armbian-config` cannot change to these kernels.
These packages are not in an apt repository.

## Upgrade U-Boot

A U-Boot upgrade is not required unless the bootloader files change.
A kernel upgrade leaves the bootloader in place.
Build U-Boot again only when a file under `patch/u-boot/v2026.10/` for this board changes.

```bash
./compile.sh uboot BOARD=rk3128-box BRANCH=current CPUTHREADS=18
```

Copy `linux-u-boot-rk3128-box-current_*.deb` to the board.
Install that deb on the board.
The install copies the files to `/usr/lib/linux-u-boot-current-rk3128-box/`.
The install does not write U-Boot to the disk.

```bash
sudo apt-mark unhold linux-u-boot-rk3128-box-current
sudo dpkg -i linux-u-boot-rk3128-box-current_*.deb
sudo apt-mark hold linux-u-boot-rk3128-box-current
```

The examples use the eMMC, `/dev/mmcblk1`.
Use `/dev/mmcblk0` for the SD card.
Check the name with `lsblk`.

Back up the first 16 MiB of the disk.
That area holds the loader, U-Boot, and the U-Boot copy.

```bash
sudo dd if=/dev/mmcblk1 of=/root/uboot-backup.bin bs=512 count=32768
```

Write U-Boot to the disk.

```bash
sudo bash -c 'source /usr/lib/u-boot/platform_install.sh && write_uboot_platform "$DIR" /dev/mmcblk1'
```

Compare the disk with the files before the reboot.
Each line must show `ok`.

```bash
d=/usr/lib/linux-u-boot-current-rk3128-box
for e in idbloader.bin:64 uboot.img:8192 uboot.img:16384; do
	f=$d/${e%%:*}
	a=$(sha256sum < "$f")
	b=$(sudo dd if=/dev/mmcblk1 bs=512 skip=${e##*:} status=none | head -c "$(stat -c %s "$f")" | sha256sum)
	[ "$a" = "$b" ] && echo "ok $e" || echo "MISMATCH $e"
done
```

If a line shows `MISMATCH`, restore the backup. Do not reboot.
The restore skips the partition table in sector 0.

```bash
sudo dd if=/root/uboot-backup.bin of=/dev/mmcblk1 bs=512 skip=64 seek=64 conv=fsync
```

Replace `current` with `edge` on an edge image.
A bad U-Boot stops the boot.
The backup does not help when Linux does not start.
Keep an SD card with a working image near the board.

### Why `FORCE_UBOOT_UPDATE=yes` does not work

An earlier version of this page used this command.

```bash
sudo FORCE_UBOOT_UPDATE=yes dpkg -i linux-u-boot-rk3128-box-current_*.deb
```

The command installs the files, but it does not write U-Boot.
The package `postinst` sources `/etc/armbian-release` before it reads the variable.
That file has the line `FORCE_UBOOT_UPDATE=` with an empty value.
The empty value replaces `yes` from the command line.
The `postinst` reads an empty value as `no` and skips the write.
The build writes the board setting to that file.
The rk3128-box board does not set `FORCE_UBOOT_UPDATE`.

## Recover from a bad kernel

Boot from an Armbian SD card.
Mount the eMMC.
Point the boot links back to the old kernel.
`<old>` is the old version, for example `6.18.58-current-rockchip`.

```bash
sudo mount /dev/mmcblk1p1 /mnt
cd /mnt/boot
ls vmlinuz-* uInitrd-* dtb-*
sudo ln -sf vmlinuz-<old> zImage
sudo ln -sf uInitrd-<old> uInitrd
sudo ln -sfn dtb-<old> dtb
cd /
sudo umount /mnt
```

Remove the SD card and power on the board.
An SD card boots the box even with a bad U-Boot on the eMMC.
In Loader or MaskROM mode, use `rkdeveloptool` or `rkflash`.
The USB loader is `rk31/rk3128_loader_v2.05.240.bin` from rkbin.

## Check the eMMC speed

```bash
sudo grep -E "^(actual clock|bus width|timing spec)" /sys/kernel/debug/mmc1/ios
echo 3 | sudo tee /proc/sys/vm/drop_caches
sudo dd if=/dev/mmcblk1 of=/dev/null bs=1M count=256 iflag=direct
```

The expected values are 50 MHz, 8 bits, and about 40 MB/s.
