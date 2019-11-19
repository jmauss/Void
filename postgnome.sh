#!/usr/bin/env bash

ask_for_username()
{
    while [ 1 ]; do
	read -p "Enter your name: " name;
        read -p "Enter your username: " user_name;
        if [ $user_name ]; then
            break;
        fi
    done
}

ask_for_username

xbps-install -Sy zsh zsh-completions

useradd -c $name -m -g wheel -s /bin/zsh $user_name 

passwd $user_name

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

sudo -u $user_name sudo xbps-install -Syu

# Gnome Core
sudo -u $user_name sudo xbps-install -Sy gnome xdg-user-dirs # Desktop Environment
sudo -u $user_name sudo xbps-install -Sy mesa-intel-dri # Video Drivers
sudo -u $user_name sudo xbps-install -Sy xf86-input-libinput  # Input
sudo -u $user_name sudo xbps-install -Sy fonts-roboto-ttf liberation-fonts-ttf noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji # Fonts
sudo -u $user_name sudo xbps-install -Sy papirus-icon-theme # Theming

# Utils
sudo -u $user_name sudo xbps-install -Sy baobab gnome-boxes gnome-calculator gnome-calendar gnome-disk-utility gnome-maps gnome-screenshot gnome-system-monitor gnome-terminal totem # Gnome
sudo -u $user_name sudo xbps-install -Sy git # Remote file tools
sudo -u $user_name sudo xbps-install -Sy ntfs-3g dosfstools exfat-utils unzip p7zip-unrar # Files/Filesystems
sudo -u $user_name sudo xbps-install -Sy neofetch # Command Line

usermod -aG libvirt $user_name

# Services
ln -s /etc/sv/libvirtd /var/service
ln -s /etc/sv/virtlockd /var/service
ln -s /etc/sv/virtlogd /var/service
ln -s /etc/sv/dbus /var/service
ln -s /etc/sv/gdm /var/service
ln -s /etc/sv/NetworkManager /var/service
ln -s /etc/sv/bluetoothd /var/service

rm -R /var/service/agetty-tty{4..6}

# Pull dotfiles
curl https://raw.githubusercontent.com/jmauss/Void/master/.zshrc -o /home/$user_name/.zshrc

# Fix Shortcuts
mkdir -p /home/$user_name/.local/share/applications
cp /usr/share/applications/{org.gnome.Cheese,yelp,org.freedesktop.IBus.Setup}.desktop /home/$user_name/.local/share/applications/
echo "NoDisplay=true" | tee -a /home/$user_name/.local/share/applications/*.desktop

# Fix permissions
chown -R $user_name:wheel /home/$user_name/
xdg-user-dirs-update

sudo -u $user_name sudo xbps-remove -Oo

rm /home/$user_name/.bash*
rm -r *
poweroff
