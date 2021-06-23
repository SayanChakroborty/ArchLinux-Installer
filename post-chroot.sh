#!/bin/sh


echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nUpdating Pacman Configuration (this time for installation destination system)...\n"

sed -i 's #Color Color ; s #ParallelDownloads ParallelDownloads ; s #\[multilib\] \[multilib\] ; /\[multilib\]/{n;s #Include Include }' /etc/pacman.conf

pacman-key --init

pacman-key --populate archlinux

echo -e "--save /etc/pacman.d/mirrorlist\n--country Sweden,Denmark\n--protocol https\n--score 10\n" > /etc/xdg/reflector/reflector.conf

reflector --save /etc/pacman.d/mirrorlist --country Sweden,Denmark --protocol https --score 10 --verbose

pacman -Syyu --noconfirm

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nReading all fields from the file confidentials...\n"

read -r user uspw rtpw host tmzn < /root/confidentials

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nSetting Localtime...\n"

ln -sf /usr/share/zoneinfo/$tmzn /etc/localtime

hwclock --systohc

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring Locale...\n"

# enable US English language and locale (might be necessary for some programs like steam)
sed -i 's #en_US.UTF-8 en_US.UTF-8 ' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nAccount Management...\n"

# set hostname
echo -e "$host" > /etc/hostname

# set root password
echo -e "$rtpw\n$rtpw" | passwd root

echo -e "\nCreating New User...\n"

useradd -m -G wheel -s /bin/zsh $user

# set user password
echo -e "$uspw\n$uspw" | passwd $user

# bypass sudo password prompt
echo -e "root ALL=(ALL) NOPASSWD: ALL\n%wheel ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/00_nopasswd

# bypass polkit password prompt
cat << EOT >> /etc/polkit-1/rules.d/49-nopasswd_global.rules
/* Allow members of the wheel group to execute any actions
 * without password authentication, similar to "sudo NOPASSWD:"
 */
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOT

cat << EOT >> /etc/polkit-1/rules.d/50-udisks.rules
// Original rules: https://github.com/coldfix/udiskie/wiki/Permissions
// Changes: Added org.freedesktop.udisks2.filesystem-mount-system, as this is used by Dolphin.

polkit.addRule(function(action, subject) {
  var YES = polkit.Result.YES;
  // NOTE: there must be a comma at the end of each line except for the last:
  var permission = {
    // required for udisks1:
    "org.freedesktop.udisks.filesystem-mount": YES,
    "org.freedesktop.udisks.luks-unlock": YES,
    "org.freedesktop.udisks.drive-eject": YES,
    "org.freedesktop.udisks.drive-detach": YES,
    // required for udisks2:
    "org.freedesktop.udisks2.filesystem-mount": YES,
    "org.freedesktop.udisks2.encrypted-unlock": YES,
    "org.freedesktop.udisks2.eject-media": YES,
    "org.freedesktop.udisks2.power-off-drive": YES,
    // Dolphin specific
    "org.freedesktop.udisks2.filesystem-mount-system": YES,
    // required for udisks2 if using udiskie from another seat (e.g. systemd):
    "org.freedesktop.udisks2.filesystem-mount-other-seat": YES,
    "org.freedesktop.udisks2.filesystem-unmount-others": YES,
    "org.freedesktop.udisks2.encrypted-unlock-other-seat": YES,
    "org.freedesktop.udisks2.eject-media-other-seat": YES,
    "org.freedesktop.udisks2.power-off-drive-other-seat": YES
  };
  if (subject.isInGroup("storage")) {
    return permission[action.id];
  }
});
EOT

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring AUR...\n"

sudo -u $user mkdir /home/$user/AUR/

cd /home/$user/AUR/

sudo -u $user git clone https://aur.archlinux.org/yay-bin.git

cd ./yay-bin

sudo -u $user makepkg -si --noconfirm

sudo -u $user yay -Syyu --noconfirm

cd /

rm -rf /home/$user/AUR

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring Plymouth...\n"

sudo -u $user yay -S --noconfirm plymouth-git

if [ -z "$(pacman -Qs plymouth-git)" ]

then

echo -e "\nCould not install plymouth\n"

else

touch /home/$user/.hushlogin

echo "kernel.printk = 3 3 3 3" >> /etc/sysctl.d/20-quiet-printk.conf

mkdir /etc/systemd/system/getty@tty1.service.d/

echo -e "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $user --noclear %I $TERM" > /etc/systemd/system/getty@tty1.service.d/skip-prompt.conf

sed -i '/^MODULES/ s/(.*)/(i915)/' /etc/mkinitcpio.conf

sed -i '/^HOOKS/ s/udev/systemd sd-plymouth/' /etc/mkinitcpio.conf

cp "/usr/lib/systemd/system/systemd-fsck-root.service" "/etc/systemd/system/systemd-fsck-root.service"

cp "/usr/lib/systemd/system/systemd-fsck@.service" "/etc/systemd/system/systemd-fsck@.service"

sed -i '/^ExecStart*/aStandardOutput=null\nStandardError=journal+console' /etc/systemd/system/systemd-fsck*.service

plymouth-set-default-theme -R bgrt

fi

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nConfiguring Bootloader (systemd-boot) ...\n"

bootctl --path=/boot install

echo -e "default arch.conf\ntimeout 0\nconsole-mode auto\neditor no\n" > /boot/loader/loader.conf

echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /intel-ucode.img\ninitrd /initramfs-linux.img\noptions root="LABEL=System" rw quiet loglevel=0 rd.systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0 splash=silent i915.fastboot=1" > /boot/loader/entries/arch.conf

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nFinishing Touch...\n"

# adjust swappiness value to increase I/O performance (modify to change desired values)
echo -e "\nvm.swappiness = 0\nvm.dirty_background_bytes = 4194304\nvm.dirty_bytes = 4194304\n" >> /etc/sysctl.conf

sysctl -p

echo -e "\nGTK_USE_PORTAL=1\n" >> /etc/environment

cat << EOT >> /home/$user/.zshrc
autoload -Uz promptinit
promptinit
prompt adam2
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/doc/pkgfile/command-not-found.zsh
autoload -Uz run-help
alias help=run-help
EOT

cat << EOT >> /etc/zsh/zshrc
autoload -Uz promptinit
promptinit
prompt adam2
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/doc/pkgfile/command-not-found.zsh
autoload -Uz run-help
alias help=run-help
EOT

sed -i '/^#governor/ s #  ; /^governor/ s ondemand performance ' /etc/default/cpupower

systemctl enable NetworkManager dhcpcd dnsmasq bluetooth cpupower haveged

if [ -z "$(pacman -Qs plymouth)" ]

then

systemctl enable sddm

else

systemctl enable sddm-plymouth

fi

pkgfile --update

appstreamcli refresh-cache --force --verbose

echo -e "\nFinally Done.\n\n"

exit
