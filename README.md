# Braiins OS Build System for Braiins Control Board (BCB)

This repository contains the build system for Braiins OS (BOS) for the Braiins Control Board (BCB). It provides all
necessary scripts and configurations to download required dependencies and build SD card and eMMC images compatible with
BCB 100.

## Features

- Automated download of all dependent repositories
- Build system for generating BOS images for BCB 100
- Support for both original BCB control boards and Braiins Miniminer 100

## Requirements

- A system compatible with Nix (e.g., Ubuntu, Debian, NixOS, etc.)
- Git (only required if you prefer not to use the version provided by Nix)
- Nix as the sole build dependency
- Optionally, shell scripts can be executed directly from the script directory, but this requires manually installing
  all utilities listed in `flake.nix` (not recommended)

## Getting Started

### Clone the Repository

```shell
nix shell nixpkgs#git --command git clone git@github.com:braiins/bos-build.git
cd bos-build
```

### Fetch Dependencies and Initialize

#### Nix

```shell
nix run .#bootstrap
nix run .#configure
```

#### Shell only (not recommended)

```shell
./scripts/00_bootstrap.sh
./scripts/01_configure.sh
```

### Build the Images

#### Nix

```shell
nix run .#make
```

#### Shell only (not recommended)

```shell
./scripts/02_make.sh
```

### Package Configuration (Optional)

```shell
nix run .#make -- menuconfig
```

### Development (Optional)

Standard OpenWrt development process with reproducible Nix environment.

```shell
cd build/openwrt/
./scripts/nix.sh make menuconfig
./scripts/nix.sh make -j$(($(nproc)+1))
```

## Output

After a successful build, the generated BOS/OpenWrt images will be available in the
`./build/openwrt/bin/targets/stm32mp15/ii1/` directory.

### eMMC Images

- `openwrt-stm32mp15-ii1-emmc-mmcblk0bootx.img.gz` - First stage bootloader (FSBL): *Trusted Firmware-A*
- `openwrt-stm32mp15-ii1-emmc-mmcblk0.img.gz` - Firmware Image Package (FIP): *U-Boot*
- `openwrt-stm32mp15-ii1-emmc-squashfs-mmcblk0gp0.img` - SquashFS image file as rootfs
- `openwrt-stm32mp15-ii1-emmc-squashfs-sysupgrade.tar` - OpenWrt sysupgrade image for eMMC only

### SD Images

- `openwrt-stm32mp15-ii1-sd-squashfs-user.img.gz` - Packed SD card image with the whole system
- `openwrt-stm32mp15-ii1-sd-squashfs-sysupgrade.tar` - OpenWrt sysupgrade image for SD only

## Manual Flashing

The initial flashing process for the Braiins Control Board assumes that the system is running from an SD card. To flash
the board manually, first boot from the SD card containing the BOS image. Once the system is up and running, you can
write the BOS image to the internal eMMC storage. This process ensures a proper installation and allows switching
between different versions if needed.

### OTP Programming

```shell
# For test purpose you can get current random mac from ifconfig
mac=$(ifconfig | grep eth0 | awk '{print $NF}')

# Write MAC stored in 'mac' variable (expected format is 'AA:BB:CC:DD:EE:FF')
echo -n "${mac//:/}0000" | xxd -r -p > "/tmp/mac"
dd if=/tmp/mac of=/sys/bus/nvmem/devices/stm32-romem0/nvmem bs=4 seek=57

# Write BCB100 Board Serial Number
# P02           : BCB100A0A000000000000000 (Fist limited series)
# P03 (rev A1.1): BCB100A1A100000000000000
# P03 (rev A1.2): BCB100A1A300000000003A12 (BMM 100)
echo -n "BCB100A1A100000000000000" | xxd -r -p > "/tmp/board_sn"
dd if=/tmp/board_sn of=/sys/bus/nvmem/devices/stm32-romem0/nvmem bs=4 seek=60

# For board that is for internal purpose generate random miner_hwid
dd if=/dev/urandom bs=1 count=12 2>/dev/null | base64 | tr "+/" "ab" | base64 -d  > "/tmp/miner_hwid"
dd if=/tmp/miner_hwid of=/sys/bus/nvmem/devices/stm32-romem0/nvmem bs=4 seek=63
```

### Hardware Partitioning

```shell
mmc enh_attrs set 0x03 /dev/mmcblk0
mmc gp create -c 49152 1 1 0 /dev/mmcblk0
mmc write_reliability set -c 1 /dev/mmcblk0
mmc enh_area set -c 0 344064 /dev/mmcblk0

# WARNING: with parameter '-y' it is a one-time programmable (irreversible) change!
mmc write_reliability set -y 0 /dev/mmcblk0

# Needs power cycle
```

### Image Flashing

```shell
# Copy all eMMC images into /tmp/images

cd /tmp/images
gzip -d *.gz

# Set env variables FIP and FSBL so they are pointing to correct files 
# depending on your board revision. Choose file with "_p03_a12.img" suffix 
# for the latest board revision (P03 A1.2, aka the final one with LCD connector).
FSBL=openwrt-stm32mp15-ii1-emmc-mmcblk0bootx.img
FIP=openwrt-stm32mp15-ii1-emmc-mmcblk0.img

# Enable write access
echo 0 > /sys/class/block/mmcblk0boot0/force_ro
echo 0 > /sys/class/block/mmcblk0boot1/force_ro

# <send_ack> =1 to enable the boot acknowledge bit in the eMMC ext_csd register
mmc bootbus set single_backward x1 x1 /dev/mmcblk0

# WARNING: Erase the entire 'fip' partition if it was previously flashed!
dd if=/dev/zero of=/dev/mmcblk0 bs=4M count=4

dd if=$FSBL of=/dev/mmcblk0boot0 bs=4096 conv=fsync
dd if=$FSBL of=/dev/mmcblk0boot1 bs=4096 conv=fsync

mmc bootpart enable 1 1 /dev/mmcblk0

dd if=$FIP of=/dev/mmcblk0 bs=4096 conv=fsync
dd if=openwrt-stm32mp15-ii1-emmc-squashfs-mmcblk0gp0.img of=/dev/mmcblk0gp0 bs=4M conv=fsync

sync
```

## Supported Hardware

- **Braiins Control Board (BCB 100)** – Standard BCB board
- **Braiins Miniminer 100 (BMM 100)** – Uses the same BCB 100 board with an additional display connector

## Contribution

Contributions are welcome! Feel free to open issues and pull requests.

## License

This project is licensed under the GNU GPL v3.0 License - see the [LICENSE](LICENSE) file for details.

## Contact

For any inquiries, reach out via [Braiins GitHub](https://github.com/braiins) or open an issue in this repository.
