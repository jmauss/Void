#!/usr/bin/env sh

# Script to partition disks and install Void Linux on UEFI

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
    (
    echo n # New partition
    echo 5 # Partition number 2
    echo   # Start immediately after previous partition
    echo   # Extend to the end of disk
    echo w # Write the partition table
    ) | fdisk "$DISK"

    mkfs.ext4 "${DISK}p5"
}

system_install()
{
    mount "${DISK}p5" /mnt/
    mkdir -p /mnt/boot/
    mount "${DISK}p1" /mnt/boot/

    export XBPS_ARCH=x86_64 && yes Y | xbps-install -Sy -R http://alpha.us.repo.voidlinux.org/current/ -r /mnt base-system grub-x86_64-efi void-repo-nonfree curl
    xbps-install -Sy -R http://alpha.us.repo.voidlinux.org/current/nonfree -r /mnt nvidia
    mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
    mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
    mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
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

    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/default/libc-locales
    chroot /mnt xbps-reconfigure -f glibc-locales

    ROOTID=$(blkid -s UUID -o value "${DISK}p5")
    BOOTID=$(blkid -s UUID -o value "${DISK}p1")
    sed -i "/^# <file system>/aUUID=$BOOTID\t\t/boot\tvfat\trw,relatime\t0\t2\nUUID=$ROOTID\t/\text4\trw,relatime\t0\t1" /mnt/etc/fstab

    cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
    sed -i 's/.de./.us./' /mnt/etc/xbps.d/*
}

bootloader()
{
    chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Void Linux" --recheck
    chroot /mnt os-prober
    chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    chroot /mnt xbps-reconfigure -af
}

echo "-----------------------------"
echo "| Void Linux Install Script |"
echo "-----------------------------"

choose_disk
set_hostname
partition_disk
system_install
system_config
bootloader
umount -R /mnt
sleep 5
poweroff
