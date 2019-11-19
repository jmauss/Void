#!/usr/bin/env sh

ask_for_username()
{
    while [ 1 ]; do
        read -p "Enter your username: " user_name;
        if [ $user_name ]; then
            break;
        fi
    done
}

chown root:root /
chmod 755 /

xbps-install -Sy zsh zsh-completions

ask_for_username

groupadd power
useradd -m -g wheel -G power,audio -s /bin/zsh $user_name 

passwd $user_name

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i '/^%wheel ALL=(ALL) ALL/a%power ALL=NOPASSWD: /usr/bin/poweroff, /usr/bin/reboot' /etc/sudoers

sudo -u $user_name sudo xbps-install -Syu

# dwm/st core
sudo -u $user_name sudo xbps-install -Sy xorg-server xorg-apps xautolock mesa-intel-dri # Display server
sudo -u $user_name sudo xbps-install -Sy xf86-input-libinput sxhkd # Input
sudo -u $user_name sudo xbps-install -Sy fontconfig font-awesome5 liberation-fonts-ttf noto-fonts-ttf noto-fonts-cjk noto-fonts-emoji # Fonts
sudo -u $user_name sudo xbps-install -Sy compton dmenu feh # dwm utils
sudo -u $user_name sudo xbps-install -Sy lxappearance gnome-themes-standard # Theming
sudo -u $user_name sudo xbps-install -Sy make musl-devel tcc pkg-config libXinerama-devel libXft-devel freetype-devel fontconfig-devel libX11-devel ncurses st-terminfo libXrandr-devel # Build tools 

# Audio
sudo -u $user_name sudo xbps-install -Sy alsa-utils pulseaudio alsa-plugins-pulseaudio pulsemixer
ln -s /etc/sv/alsa /var/service

# Utils
sudo -u $user_name sudo xbps-install -Sy git # Remote file tools
sudo -u $user_name sudo xbps-install -Sy ntfs-3g dosfstools exfat-utils unzip p7zip-unrar xar # Files/Filesystems
sudo -u $user_name sudo xbps-install -Sy acpi # Hardware monitoring

# Programs
sudo -u $user_name sudo xbps-install -Sy neofetch htop ranger # Command Line
sudo -u $user_name sudo xbps-install -Sy mpv # Graphical
sudo -u $user_name sudo xbps-install -Sy qemu virt-manager dbus ebtables # Virtualization
ln -s /etc/sv/libvirtd /var/service
ln -s /etc/sv/virtlockd /var/service
ln -s /etc/sv/virtlogd /var/service
ln -s /etc/sv/dbus /var/service
usermod -aG libvirt $user_name

# Create directories
mkdir -p /home/$user_name/.local/bin
mkdir -p /home/$user_name/.local/share/fonts/
mkdir -p /home/$user_name/builds
mkdir -p /home/$user_name/downloads
mkdir -p /home/$user_name/images
mkdir -p /home/$user_name/.config/compton
mkdir -p /home/$user_name/.config/sxhkd
chown -R $user_name:wheel /home/$user_name/

# Install fonts
cd /home/$user_name/.local/share/fonts/
sudo -u $user_name git clone https://github.com/jmauss/SF-Mono-Font

curl -L -O https://developer.apple.com/fonts/downloads/SFPro.zip
unzip SFPro.zip
cd SFPro/
mkdir pkg
xar -xf 'San Francisco Pro.pkg' -C pkg
gunzip -dc "pkg/San Francisco Pro.pkg/Payload" | cpio -i
cd Library/Fonts/
mkdir /home/$user_name/.local/share/fonts/SF-Pro-Font/
mv * /home/$user_name/.local/share/fonts/SF-Pro-Font/
cd /home/$user_name/.local/share/fonts/
rm -R SFPro/
rm -R __MACOSX/
rm SFPro.zip

fc-cache -v -f

# Build dwm
cd /home/$user_name/builds
sudo -u $user_name git clone https://github.com/jmauss/dwm
cd dwm
sudo -u $user_name make
make clean install
cd ..

# Build st
sudo -u $user_name git clone https://github.com/jmauss/st
cd st
sudo -u $user_name make
make clean install
cd ..

# Build slock
sudo -u $user_name git clone https://github.com/jmauss/slock
cd slock
sudo -u $user_name make
make clean install
cd

# Pull dotfiles
curl https://raw.githubusercontent.com/jmauss/Void/master/.xinitrc -o /home/$user_name/.xinitrc
curl https://raw.githubusercontent.com/jmauss/Void/master/.xprofile -o /home/$user_name/.xprofile
curl https://raw.githubusercontent.com/jmauss/Void/master/.zprofile -o /home/$user_name/.zprofile
curl https://raw.githubusercontent.com/jmauss/Void/master/.zshrc -o /home/$user_name/.zshrc
curl https://raw.githubusercontent.com/jmauss/Void/master/config/user-dirs.dirs -o /home/$user_name/.config/user-dirs.dirs
curl https://raw.githubusercontent.com/jmauss/Void/master/config/compton/compton.conf -o /home/$user_name/.config/compton/compton.conf
curl https://raw.githubusercontent.com/jmauss/Void/master/config/sxhkd/sxhkdrc -o /home/$user_name/.config/sxhkd/sxhkdrc
curl https://raw.githubusercontent.com/jmauss/Void/master/local/bin/dstat -o /home/$user_name/.local/bin/dstat
curl https://raw.githubusercontent.com/jmauss/Void/master/local/bin/rbar -o /home/$user_name/.local/bin/rbar

# Fix permissions
chown -R $user_name:wheel /home/$user_name/
find /home/$user_name -type d -print0 | xargs -0 chmod 0755
find /home/$user_name -type f -print0 | xargs -0 chmod 0644
chmod +x /home/$user_name/.local/bin/dstat
chmod +x /home/$user_name/.local/bin/rbar

sudo -u $user_name sudo xbps-remove -Oo

rm /home/$user_name/.bash*
rm -r *
poweroff
