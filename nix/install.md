# NixOS Installation

## Static IP Setup

```bash
ifconfig <interface> <static-ip> netmask <netmask>
```

## Paritioning

In this example we are going to use a 512MB boot partiton and a 4GB swap partition at the end of the disk. All other space on the disk will be reserved for the root partition.

### Finding the disk

You can use the `parted` utility to find the disk you want to use

```bash
parted -l
```

This will return a list of disks and partitions.

```
[root@nixos:~]# parted -l
Model: Samsung Flash Drive (scsi)
Disk /dev/sda: 128GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start   End     Size    Type     File system  Flags
 2      11.4MB  14.5MB  3146kB  primary               esp


Model: APPLE SSD AP0512M (nvme)
Disk /dev/nvme0n1: 500GB
Sector size (logical/physical): 4096B/4096B
Partition Table: gpt
Disk Flags:

Number  Start  End    Size    File system  Name  Flags
```

In this case, I will use `/dev/nvme0n1` to install NixOS onto.

### Create the partition table

```bash
parted /dev/nvme0n1 -- mklabel gpt
```

### Create the partitions

```bash
parted /dev/nvme0n1 -- mkpart root ext4 512MB -4GB
parted /dev/nvme0n1 -- mkpart swap linux-swap -4GB 100%
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
# I recommend running `parted --list` to ensure you are using the correct partition numner for setting `esp`.
parted /dev/nvme0n1 -- set 3 esp on
```

### Format the partition

I recommend starting with a `parted --list` to confirm that you are interacting with the correct partitions before formatting. The number displayed is the number you should use for the partition. `fdisk -l` may be helpful here as well if things are unclear.

```bash
mkfs.ext4 -L nixos /dev/nvme0n1
mkswap -L swap /dev/nvme0n1p2
mkfs.fat -F 32 -n boot /dev/nvme0n1p3
```

### Mount the disk to install to

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
```

If you are memory constrained, you can enable the swap partition as well

```bash
swapon /dev/nvme0n1p2
```

## Generate the NixOS configuration

```bash
nixos-generate-config --root /mnt
```

## Edit the NixOS configuration

```
vi /mnt/etc/nixos/configuration.nix
```

### Confirm bootloader

This setting should already be set, but I recommend checking it

```
boot.loader.systemd-boot.enable = true;
```

### Set hostname

```
networking.hostName = "host00";
```

### Set timezone

```
time.timeZone = "America/Chicago";
```

### Set locale

```
i18n.defaultLocale = "en_US.UTF-8";
```

### Enable X11 (optional, not recommended for servers)

```
services.xserver.enable = true;
```

### Define a user account

> We will set a password later...

```
users.users.deployer = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
  packages = with pkgs; [
    tree
  ];
}
```

### List packages to be installed

We will list a couple of packages to be installed on the system. You can search for a package using the nix package manager via `nix search <package>`.


```
environmane.systemPackages = with pkgs; [
  vim
  wget
];
```

> We will want a text editor (`vim` in this case) at a minimum to ensure that we can edit the configuration files and declaritively define the configuration of the system.

### Enable SSH

```
services.openssh.enable = true;
```

### Write and quit

`<ESC>:wq<ENTER>`

## Validate the `hardware-configuration.nix` file

This should include some information on mounting the filesystems. This should be automatically generated by the `nixos-generate-config` command, but it's a good idea to check it manually.

```bash
vim /mnt/etc/nixos/hardware-configuration.nix
```

## Perform the installation

```bash
nixos-install
```

This will guide you through the installation and at the end will ask you to set the root password.

## Set the user password

Using the username you defined in the `configuration.nix`, run the following

```bash
nixos-enter --root /mnt -c 'passwd brandonyoung'
```
