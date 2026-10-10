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

Install both packages on the board.

```bash
sudo dpkg -i linux-image-edge-sunxi64_*.deb linux-dtb-edge-sunxi64_*.deb
sudo apt-mark hold linux-image-edge-sunxi64 linux-dtb-edge-sunxi64
sudo reboot
```

Replace `edge` with `current` on a current kernel.
Official Armbian packages use these same names.
Those packages omit the IK316 device tree.
Keep the hold in place.
`dpkg -i` still installs a local package.

A U-Boot upgrade is not required unless the bootloader files change.
A kernel upgrade leaves the bootloader in place.
Build U-Boot again only when a file under `patch/u-boot/v2026.07-sunxi64/board_ik316/` changes.
Those files set the DRAM timings and the eMMC boot device.

```bash
./compile.sh uboot BOARD=ik316 BRANCH=edge
```

Copy `linux-u-boot-ik316-edge_*.deb` to the board.
Install that deb on the board.

```bash
sudo FORCE_UBOOT_UPDATE=yes dpkg -i linux-u-boot-ik316-edge_*.deb
```

The package writes U-Boot to the root disk.
The binary directory is `/usr/lib/linux-u-boot-edge-ik316/`.
Replace `edge` with `current` on a current image.
