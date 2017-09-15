#!/bin/bash

if [ "`whoami`" != 'root' ]; then
  echo 'Please run as "root".'
  exit 1
fi

USER_NAME="$1"
if [ "$USER_NAME" == '' ]; then
  echo "Usage: bash $0 <User Name>"
  exit 1
fi

set -euo pipefail


### Enable for $USER_NAME to use "sudo" command ###
SUDOERS_FILE='/etc/sudoers'
chmod 600 $SUDOERS_FILE
echo "$USER_NAME ALL=(ALL:ALL) ALL" >> $SUDOERS_FILE
chmod 440 $SUDOERS_FILE

### Pass through GRUB menu ###
GRUB_CONFIG_FILE='/etc/default/grub'
sed -re 's/^(GRUB_TIMEOUT=)[0-9]+$/\10/' $GRUB_CONFIG_FILE -i
update-grub

### Pass through LightDM Login ###
LIGHT_DM_CONFIG_FILE='/etc/lightdm/lightdm.conf'
sed -re "s/^#(autologin-user=).*$/\1$USER_NAME/" $LIGHT_DM_CONFIG_FILE -i
sed -re 's/^#(autologin-user-timeout=.*)$/\1/'   $LIGHT_DM_CONFIG_FILE -i

### Change directories' name from JPN to EN
apt install xdg-user-dirs-gtk
su - $USER_NAME -c 'LANG=C xdg-user-dirs-gtk-update'
### NOTICE: Check "Don't ask me again" box ###

### Add mirror site ###
echo 'deb http://ftp.jp.debian.org/debian/ stretch main contrib non-free' >> /etc/apt/sources.list

### Remove unused packages ###
apt-get purge -y pluma galculator firefox-esr thunderbird atril libreoffice-common libreoffice-core gimp eom gnome-orca goldendict khmerconverter
apt-get autoremove --purge -y
apt-get autoclean

apt update
apt upgrade -y

### Rename NIC name to eth0 ###
sed -re 's/^(GRUB_CMDLINE_LINUX)=""$/\1="net.ifnames=0 biosdevname=0"/' $GRUB_CONFIG_FILE -i
grub-mkconfig -o /boot/grub/grub.cfg
echo '
  auto eth0
  iface eth0 inet dhcp
' > /etc/network/interfaces.d/eth0


echo 'Please reboot Debian.'
