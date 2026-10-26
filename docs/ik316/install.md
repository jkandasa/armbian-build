# IK316 install and update

## Fresh install

Build the image on the host.

```bash
./compile.sh build BOARD=ik316 BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie
```

Set `CPUTHREADS` to the number of compile jobs.
The default is one and a half times the host CPU count.
Use a positive integer.
The same option applies to the kernel command and the U-Boot command.

```bash
./compile.sh build BOARD=ik316 BRANCH=edge BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=trixie CPUTHREADS=8
```

Use `BRANCH=current` for the 6.18 kernel.
The board sets `BSPFREEZE=yes`.
The image then holds the board packages.
Add `BSPFREEZE=no` to build an image without the hold.
The build needs 10 GiB free in `output/` and in `cache/`.

The image file is under `output/images/`.
The file name contains `Ik316`.

Log in as `root`.
The initial password is `1234`.
Change that password at the first console login.
SSH is enabled.
The hostname is `ik316`.
Ethernet uses DHCP on `end0`.

## Write the image to an SD card

Find the SD card with `lsblk`.
Use the whole disk, for example `/dev/sdX`.
The write erases that whole disk.

```bash
sudo dd if=output/images/Armbian_*_Ik316_*_minimal.img of=/dev/sdX bs=4M conv=fsync status=progress
```

You can also flash from the build tree.

```bash
./compile.sh flash BOARD=ik316 CARD_DEVICE=/dev/sdX
```

Insert the card and power on the board.

## Move the system to eMMC

Boot from the SD card.
Run `lsblk`.
On this board the eMMC is the 7.3 GiB disk.
Confirm that name before the next command.
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

## Package freeze

The board packages use the official Armbian package names.
The official kernel packages omit the IK316 device tree and the `ssv6x5x` module.
`apt upgrade` can replace the board kernel.
The box then does not boot.

The board sets `BSPFREEZE=yes`.
The image build then runs `apt-mark hold` on each package that the build made.
These packages are frozen on an edge image.

| Package                      | Content                          |
| ---------------------------- | -------------------------------- |
| `linux-image-edge-sunxi64`   | Kernel and `ssv6x5x` module      |
| `linux-dtb-edge-sunxi64`     | Device trees with the IK316 tree |
| `linux-u-boot-ik316-edge`    | U-Boot files                     |
| `armbian-bsp-cli-ik316-edge` | Board scripts and settings       |
| `armbian-firmware`           | Firmware with the Wi-Fi files    |
| `base-files`                 | Armbian base files               |

A current image freezes the `current` names of the first four packages.
The freeze does not hold the Debian packages.
`apt upgrade` updates those packages as usual.

Show the frozen packages.

```bash
apt-mark showhold
```

Images built before this change have no freeze.
Freeze the board packages on such a system.

```bash
sudo apt-mark hold linux-image-edge-sunxi64 linux-dtb-edge-sunxi64 linux-u-boot-ik316-edge armbian-bsp-cli-ik316-edge armbian-firmware base-files
```

Replace `edge` with `current` on a current kernel.
Do not use `Enable Armbian firmware upgrades` in `armbian-config`.
That entry removes the kernel hold.

## Upgrade the kernel on a running board

Read the running branch from `uname -r`.
A name with `edge` uses `BRANCH=edge`.
A name with `current` uses `BRANCH=current`.
Build the same branch on the host.

```bash
./compile.sh kernel BOARD=ik316 BRANCH=edge KERNEL_CONFIGURE=no KERNEL_BTF=no
```

Copy both debs from `output/debs/` to the board.
One deb is `linux-image-<branch>-sunxi64`.
The other deb is `linux-dtb-<branch>-sunxi64`.
Use debs with the same version.

Install both packages on the board.

```bash
sudo apt-mark unhold linux-image-edge-sunxi64 linux-dtb-edge-sunxi64
sudo dpkg -i linux-image-edge-sunxi64_*.deb linux-dtb-edge-sunxi64_*.deb
sudo apt-mark hold linux-image-edge-sunxi64 linux-dtb-edge-sunxi64
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

A U-Boot upgrade is not required unless the bootloader files change.
A kernel upgrade leaves the bootloader in place.
Build U-Boot again only when a file under `patch/u-boot/v2026.10-sunxi64/board_ik316/` changes.
Those files set the DRAM timings and the eMMC boot device.

```bash
./compile.sh uboot BOARD=ik316 BRANCH=edge
```

Copy `linux-u-boot-ik316-edge_*.deb` to the board.
Install that deb on the board.
The install copies the files to `/usr/lib/linux-u-boot-edge-ik316/`.
The install does not write U-Boot to the eMMC.

```bash
sudo apt-mark unhold linux-u-boot-ik316-edge
sudo dpkg -i linux-u-boot-ik316-edge_*.deb
sudo apt-mark hold linux-u-boot-ik316-edge
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
f=/usr/lib/linux-u-boot-edge-ik316/u-boot-sunxi-with-spl.bin
sha256sum < "$f"
sudo dd if=/dev/mmcblk2 bs=1k skip=8 status=none | head -c "$(stat -c %s "$f")" | sha256sum
```

If the hashes differ, restore the backup. Do not reboot.

```bash
sudo dd if=/root/uboot-backup.bin of=/dev/mmcblk2 bs=1k seek=8 conv=fsync
```

Replace `edge` with `current` on a current image.
A bad U-Boot on the eMMC stops the boot.
The backup does not help when Linux does not start.
Keep an SD card with a working image near the board.

### Why `FORCE_UBOOT_UPDATE=yes` does not work

An earlier version of this page used this command.

```bash
sudo FORCE_UBOOT_UPDATE=yes dpkg -i linux-u-boot-ik316-edge_*.deb
```

The command installs the files, but it does not write U-Boot.
The package `postinst` sources `/etc/armbian-release` before it reads the variable.
That file has the line `FORCE_UBOOT_UPDATE=` with an empty value.
The empty value replaces `yes` from the command line.
The `postinst` reads an empty value as `no` and skips the write.
The build writes the board setting to that file.
The ik316 board does not set `FORCE_UBOOT_UPDATE`.
