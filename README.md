# LinuxBootstrap
Bootstrap scripts for Arch linux with used softwares list.\
This guide is meant to be used with the Arch installation guide on the Arch wiki. 

# Dependency

There is no strict dependencies. Only optional ones.
* ( Optional ) The bootstrap script depends on [LinuxBoot](https://github.com/RayZ0rr/LinuxBoot) repo for bootloader and boot setup.\
( _mainly files in 'boot' folder_. But a copy exists in this repo and will be used)
* ( Optional ) [Dotfiles](https://github.com/RayZ0rr/dotfiles) repo for dotfiles for configurations and customizations.
* ( Optional ) [myNvim](https://github.com/RayZ0rr/myNeovim) repo for neovim configurations and customizations.

If you don't need _Dotfiles_ or _myNvim_ setup, then change variables `doDotfilesSetup` and `doNvimSetup` in line numbers _31_ and _32_ respectively to `"no"` or just comment them out by placing `#` at the beginning.

# Reminders: 
* Double check what is the drives name you want to install on, it might not be /dev/sda (use `lsblk` or `fdisk -l`).
* You need to install the userspace utilities for the different filesystems(xfsprogs, btrfs-progs, dosfstools).

# Partitioning
Check what drives are available with lsblk:

Usually sda or sdb is your usb drive with the Arch ISO.
Probably the biggest drive will be your computers hard drive.

You can also find scripts with the most popular system configurations in the install-scripts directory, I don't recommend executing the scripts, the best way is to copy the commands one-by-one incase you need to change something inbetween the commands.

I think the easiest to use partitioner is cfdisk
```
# cfdisk /dev/sda
```

The partition layout:
```
|EFI system partition (FAT32) | Label=part_efi | /dev/sda1 | Suggested size is 512 MiB
Mountpoint:   /efi  
|EFI system partition (ext4) | Label=part_boot | /dev/sda2 | Suggested size is 1 GiB
Mountpoint:   /boot  

Optional Linux Swap | Label=Swap | /dev/sda4 | 2x or 1.5x times bigger than ram
```
**btrfs root ('/') and home ('/home').**
```
Btrfs device | partition | mountpoint |	  Label	  | Suggested size
/dev/sda3                               part_btrfs      30 GiB
/dev/sda3         @           /
/dev/sda3       @home       /home
/dev/sda3       @var        /var
```
**ext4 root ('/') and home ('/home').**
```
ext4 device | partition | mountpoint |	  Label	  | Suggested size
/dev/sda      /dev/sda3       /         part_root       30 GiB
/dev/sda      /dev/sda4     /home       part_home   Remaining space
```

# TIP : ssh into installation system 
I recommend connecting both of your devices to the same network because it will be much easier to connect with ssh to the computer you are installing Arch on.\
First check the ip address to connect to.
```
ip a
```
Then setup sshd.
```
passwd
systemctl enable sshd
```
Connect from other computer on same network with:
```
ssh root@<ip from 'ip a' command above>
Eg:
ssh root@192.168.122.175
```
# Procedure ( before chroot)

Follow the official [Arch Installation guide](https://wiki.archlinux.org/title/Installation_guide) till till **Chroot**.

## Some example steps.

### Initial tests

```
# ls /sys/firmware/efi/efivars
# setfont sun12x22
# ping archlinux.org
# timedatectl set-ntp true
# timedatectl status
```

### Set up disks
Use `cfdisk /dev/sda` and setup the partition as shown above or however you like.\
Use `lsblk` to find out the _device_. It may not be `/dev/sda`.

### Encrypting (Optional but recommended)
```
cryptsetup luksFormat /dev/sda3
# Same as :
cryptsetup --type luks2 --cipher aes-xts-plain64 --hash sha256 --iter-time 2000 --key-size 256 --pbkdf argon2id --use-urandom --verify-passphrase luksFormat /dev/sda3
# To use a keyfile instead of passphrase use:
# (Read on keyfiles : https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles )
cryptsetup luksFormat /dev/sda3 /path/to/mykeyfile
# OR
# To add extra passphrase or keyfiles
cryptsetup luksAddKey /dev/sda3
cryptsetup luksAddKey /dev/sda3 /path/to/mykeyfile2
```
One way to generate keyfile is:
```
dd bs=512 count=4 if=/dev/random of=mykeyfile.bin iflag=fullblock
chmod 600 mykeyfile.bin
```
Read more on [keyfiles here](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles).\
Then for btrfs
```
cryptsetup open /dev/sda3 Cbtrfs
```
or for separate root and home.
```
cryptsetup open /dev/sda3 Croot
cryptsetup open /dev/sda4 Chome
```
If using keyfile then use `--key-file` or `-d` flag followed by keyfile name. Example if you used above `dd` command to generate keyfile.
```
cryptsetup open /dev/sda3 Cbtrfs --key-file mykeyfile.bin
```
Use `cryptsetup luksDump /dev/sda3` to see more information (keyslots start with number 0).
### Formatting
1. EFI system partition (_esp_) and Boot partition.
```
# mkfs.fat -F 32 -n part_efi /dev/sda1
# mkfs.ext4 -L part_boot /dev/sda2
```
2.
  * If you are using btrfs without encryption.
  ```
  # mkfs.btrfs -L part_btrfs /dev/sda3
  ```
  * If you are using btrfs encryption from above, then:
  ```
  # mkfs.btrfs -L part_btrfs /dev/mapper/Cbtrfs
  ```
  * If you are using ext4 for root and home.
  ```
  # mkfs.ext4 -L part_root /dev/sda3
  # mkfs.ext4 -L part_home /dev/sda4
  ```
  * If you are using ext4 for root and home with encryption.
  ```
  # mkfs.ext4 -L part_root /dev/mapper/Croot
  # mkfs.ext4 -L part_home /dev/mapper/Chome
  ```
3. If you have swap
```
# mkswap -L part_swap /dev/sda5
```
### Mounting

#### First mount root and then others

1. 
    1. If you have btrfs partition for root and home
    ```
    # without encryption
    mount /dev/sda3 /mnt
    # or with encryption as above
    mount /dev/mapper/Cbtrfs /mnt
    ```
    Create subvolumes as necessary.
    ```
    btrfs sub cr /mnt/@
    btrfs sub cr /mnt/@home
    btrfs sub cr /mnt/@var
    ```

    ```
    umount /mnt
    # If using unencrypted replace '/dev/mapper/Cbtrfs' with approriate one. Eg :- '/dev/sda3' .
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@ /dev/mapper/Cbtrfs /mnt
    mkdir -p /mnt/{boot,efi,home,var}
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@home /dev/mapper/Cbtrfs /mnt/home
    mount -o relatime,space_cache=v2,ssd,compress=lzo,subvol=@var /dev/mapper/Cbtrfs /mnt/var
    ```
    2. If you have ext4 partitions for root and home
    ```
    # without encryption
    mount /dev/sda3 /mnt
    mkdir -p /mnt/{boot,efi,home}
    mount /dev/sda4 /mnt/home
    # or with encryption as above
    mount /dev/mapper/Croot /mnt
    mkdir -p /mnt/{boot,efi,home}
    mount /dev/mapper/Chome /mnt/home
    ```
2. For EFI System Partition (_esp_) and Boot.
```
mount /dev/sda1 /mnt/efi
mount /dev/sda2 /mnt/boot
```
3. If you have swap
```
swapon /dev/sda5
```
### Initializing root
* Change `linux-lts` to `linux` or any other [supported kernels](https://wiki.archlinux.org/title/Kernel#Officially_supported_kernels).
* Add [microcode](https://wiki.archlinux.org/title/Microcode) (`intel-ucode` or `amd-ucode`) and [graphics drivers](https://wiki.archlinux.org/title/Xorg#Driver_installation) as required.
* Install [bootloader](https://wiki.archlinux.org/title/Arch_boot_process#Boot_loader) of your choice (only grub and rEFInd supported for bootstrap). In the example below, `grub` is used.
```
pacstrap /mnt base linux-lts linux-firmware git vim grub efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
# See note below.
arch-chroot /mnt
```
**NOTE!** If you have created `mykeyfile.bin` like above for encryption with keyfile, then make sure to move it to somewhere for further access after `arch-chroot`. Example (replace '_Chome_' with the name used for decrypting with `cryptsetup open`):
```
mkdir /mnt/etc/cryptsetup-keys.d
mv mykeyfile.bin /mnt/etc/cryptsetup-keys.d/Chome.key
arch-chroot /mnt
```
Optionally, if you are using _btrfs_, remove 'subvolid' entry from mount options in `/etc/fstab`.\
To print result to stdout without changing the file
```
sed 's/subvolid.*,//' /etc/fstab
```
If okay, then write changes to file.
```
sed -i 's/subvolid.*,//' /etc/fstab
```

# Procedure ( After chroot)

Clone bootstrap repository to `/tmp/mySetup`

```
mkdir tmp/mySetup
cd tmp/mySetup
git clone https://github.com/RayZ0rr/LinuxBootstrap
cd LinuxBootstrap/Arch
```
Optionally, edit the bootstrap script that will be used. Especially, the variables starting from _line 31_.
```
vim ./Arch_Bootstrap_[Auto|Manual].sh
```
Optionally, edit `progs.csv` if required and start bootstrapping. Use Auto or Manual script:
```
./Arch_Bootstrap_[Auto|Manual].sh
```
* Check necessary logs at `/tmp/bootstrapLogs` or `/home/<username>/bootstrapLogs`.
* Check `/boot/grub/grub.cfg` and `/boot/grub/custom.cfg` if `GRUB` is bootloader or `/boot/refind_linux.conf` if `refind` is bootloader, as necessary to make sure all entries are correct.
* Check `/etc/fstab` to make sure everything is correct along with `lsblk -f` or `blkid` to verify stuff.
* If there is more than one encrypted partition, check `/etc/crypttab` as necessary to make sure all entries are correct. Optionally, enter the keyfile path for third field for that particular partition to skip password check for home partition at boot (read more [here](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#crypttab)).

alias `la` to `ls -al` for convenience.
```
alias la="ls -al"
```

If everything is ok, then exit and reboot:
```
exit
umount -R /mnt
reboot
```

# Post-Installation Steps

You can check `~/bootstrapLogs` folder to find logs from bootstrap script. Other than that do the following:\
( _There's will be scipt in home directory named 'firstStart.sh', if dotfiles were setup, that does steps 1 to 4 below. Just run it by typing `./firstStart.sh` and reopen terminal. Don't forget to remove the script as it is unneccassry)

1. Open terminal (with 'windows key'+ enter key if not changed) and:
  * rename `~/.zshenv_hold` to `~/.zshenv` ( `mv ~/.zshenv_hold ~/.zshenv` )
  * Delete `~/.zshrc` ( `rm ~/.zshrc` )
  * Close terminal and open again.
2. Start [clipmenu](https://github.com/cdown/clipmenu) daemon to get it's features.
```
systemctl --user enable clipmenud
```
3. Use `fc-cache -fv` to reload fonts.
4. Optionally, run the below command to remove solo packages not explicitly installed and are not required by any other packages. **MAKE SURE THEY ARE NOT REQUIRED !!**
```
pacman -Qtdq | sudo pacman -Rns -
# OR
packorphan
```
5. Optionally edit `~/.config/polybar/modulesGruvbox.ini` and change [myCards] section if necessary.
<!-- 6. Edit `~/.config/polybar/config_i3.ini` (if using *i3*, use the approriate config files for other window managers) and change monitor value. -->
6. Optionally open neovim with `nvim` or `nv` in terminal to complete neovim setup.

# Reference

* [Deebble's arch-btrfs-install-guide](https://github.com/Deebble/arch-btrfs-install-guide)
