#!/usr/bin/env sh

# Script to partition disks and install encrypted Void Linux on UEFI

prompt()
{
    printf "%s" "$1"
    while read -r VAR ; do
        if echo "$VAR" | grep -Eqx "$3" ; then
            eval "$2=$VAR"
            break
        else
            printf "Invalid input! Please try again\n"
        fi
    done
}

choose_disk()
{
    echo "Available disks:"
    lsblk -dn -e 2,7,11 -p -o NAME,SIZE | column
    prompt "Installation drive: " DISK "$(lsblk -dn -e 2,7,11 -p -o NAME)"

}

set_hostname()
{
    while [ 1 ]; do
        read -p "Preferred hostname: " HOST_NAME;
        if [ "$HOST_NAME" ]; then
            break;
        fi
    done
}

partition_disk()
{
    wipefs -af "$DISK"
    (
    echo g # Clear all partition data and create a new partition (GPT)
    echo n # New partition
    echo 1 # Partition number 1
    echo   # Start at beginning of disk
    echo +512M # 512MB boot partition
    echo n # New partition
    echo 2 # Partition number 2
    echo   # Start immediately after previous partition
    echo   # Extend to the end of disk
    echo w # Write the partition table
    ) | fdisk "$DISK"

    mkfs.vfat -F32 "${DISK}p1"
}

crypt_setup()
{
    cryptsetup --verbose --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random --batch-mode luksFormat "${DISK}p2"
    cryptsetup luksOpen "${DISK}p2" crypt 

    pvcreate /dev/mapper/crypt
    vgcreate void /dev/mapper/crypt
    lvcreate -l +100%FREE -n root void

    mkfs.ext4 /dev/mapper/void-root

    mount /dev/mapper/void-root /mnt
    mkdir /mnt/boot
    mount "${DISK}p1" /mnt/boot
}

system_install()
{
    export XBPS_ARCH=x86_64 && yes Y | xbps-install -Sy -R http://alpha.us.repo.voidlinux.org/current/ -r /mnt base-system lvm2 cryptsetup grub-x86_64-efi void-repo-nonfree curl
    xbps-install -Sy -R http://alpha.us.repo.voidlinux.org/current/musl/nonfree -r /mnt intel-ucode
    mount -t proc proc /mnt/proc
    mount -t sysfs sys /mnt/sys
    mount -o bind /dev /mnt/dev
    mount -t devpts pts /mnt/dev/pts
}

system_config()
{
    echo "Choose a password for root..."
    chroot /mnt passwd

    echo $HOST_NAME > /mnt/etc/hostname
    sed -i "/^::1.*/a127.0.1.1\t\t$HOST_NAME.localdomain\t$HOST_NAME" /mnt/etc/hosts

    sed -i 's/#HARDWARECLOCK=/HARWARECLOCK=/' /mnt/etc/rc.conf
    sed -i 's/#TIMEZONE="Europe\/Madrid"/TIMEZONE="America\/Chicago"/' /mnt/etc/rc.conf
    sed -i 's/#KEYMAP="es"/KEYMAP="us"/' /mnt/etc/rc.conf

    DEVID=$(blkid -s UUID -o value "${DISK}p1")
    sed -i "/^# <file system>/aUUID=$DEVID\t\t/boot\tvfat\trw,noatime,discard\t0\t2\n/dev/mapper/void-root\t/\text4\trw,noatime,discard\t0\t1" /mnt/etc/fstab

    mkdir -p /mnt/etc/xbps.d
    cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
    sed -i 's/.de./.us./' /mnt/etc/xbps.d/*

    KERN=$(ls /mnt/lib/modules/)
    echo "# Build initrd only to boot current hardware\nhostonly=\"yes\"\n" >> /mnt/etc/dracut.conf
    echo "# Set the directory for temporary files\n# Default: /var/tmp\ntmpdir=/tmp\n" >> /mnt/etc/dracut.conf
    echo "# Enable Intel microcode\nearly_microcode=yes\n" >> /mnt/etc/dracut.conf
    chroot /mnt dracut --force --hostonly --kver "$KERN"
}

bootloader()
{
    sed -i 's/page_poison=1/page_poison=1 rd.auto=1/' /mnt/etc/default/grub
    chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Void Linux" --recheck

    SKERN=$(echo "${KERN}" | cut -f1,2 -d'.')
    chroot /mnt xbps-reconfigure -f linux"$SKERN"
}

echo "-----------------------------"
echo "| Void Linux Install Script |"
echo "-----------------------------"

choose_disk
set_hostname
partition_disk
crypt_setup
system_install
system_config
bootloader
umount -R /mnt
sleep 5
poweroff
