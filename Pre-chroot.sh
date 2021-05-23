#!/bin/sh


echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nEnter username to be created:\n"

read user

echo -e "\nEnter root password:\n"

read rtpw

echo -e "\nEnter user password:\n"

read uspw

echo -e "\nEnter device name:\n"

read host

echo -e "$user $rtpw $uspw $host" > ./passwords

echo -e "\nDone.\n\n"



echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nFormatting Partitions...\n"

wipefs --all /dev/sda

sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:BOOT /dev/sda

sgdisk -n 0:0:0 -t 0:8304 -c 0:ROOT /dev/sda

mkfs.fat -F 32 -n "ESP" /dev/sda1

mkfs.ext4 -L "System" -F /dev/sda2

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nStarting NTP Daemon...\n"

sleep 2

timedatectl set-ntp true

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nModifying Pacman Configuration...\n"

sleep 2

sed -i 's/#Color/Color/; s/#TotalDownload/TotalDownload/; s/#\[multilib\]/\[multilib\]/; /\[multilib\]/{N;s/#Include/Include/}' /etc/pacman.conf

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nPerforming Initialization of Pacman Keyring...\n"

sleep 2

pacman-key --init

pacman-key --populate archlinux

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nMounting Partitions...\n"

sleep 2

mount /dev/sda2 /mnt

rm -rf /mnt/lost*

mkdir /mnt/boot

mount /dev/sda1 /mnt/boot

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nAdding Fastest Mirror in Pacman Mirrorlist...\n"

sleep 2

echo -e "--save /etc/pacman.d/mirrorlist\n--country Sweden,Denmark\n--protocol https\n--score 10\n" > /etc/xdg/reflector/reflector.conf

reflector --save /etc/pacman.d/mirrorlist --country Sweden,Denmark --protocol https --score 10 --verbose

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nPerforming Pacstrap Operation...\n"

sleep 2

pacstrap /mnt base base-devel linux linux-docs linux-headers linux-firmware linux-tools-meta nano man-db man-pages texinfo dialog dhcpcd dnsmasq wpa_supplicant efibootmgr intel-ucode pacman-contrib pkgstats pkgfile neofetch htop git make cmake xorg mesa lib32-mesa intel-media-driver libva-intel-driver lib32-libva-intel-driver libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau xf86-video-amdgpu vulkan-icd-loader lib32-vulkan-icd-loader vulkan-intel lib32-vulkan-intel vulkan-radeon lib32-vulkan-radeon amdvlk lib32-amdvlk plasma-meta kde-applications-meta packagekit-qt5 fwupd ffmpeg gst-libav gst-plugins-base lib32-gst-plugins-base gst-plugins-good lib32-gst-plugins-good gst-plugins-bad gst-plugins-ugly libde265 gstreamer-vaapi bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-liberation ttf-droid gnu-free-fonts ttf-linux-libertine noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-roboto ttf-ubuntu-font-family ttf-opensans cantarell-fonts inter-font wqy-microhei wqy-zenhei wqy-bitmapfont otf-ipafont cpupower haveged android-tools android-file-transfer hunspell hunspell-en_US xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-kde libappindicator-gtk2 libappindicator-gtk3 lib32-libappindicator-gtk2 lib32-libappindicator-gtk3 zsh zsh-doc grml-zsh-config zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting zsh-lovers zsh-theme-powerlevel10k powerline xsettingsd autorandr reflector firefox

echo -e "\nDone.\n\n"




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nGenerating FSTab...\n"

sleep 2

genfstab -L /mnt >> /mnt/etc/fstab

echo -e "\nDone.\n\nPre-chroot step is now complete.\n\n"

sleep 2




echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo -e "\nStarting Post-chroot step...\n"

sleep 2

cp ./passwords /mnt/root/

cp ./Post-chroot.sh /mnt/root/

chmod a+x /mnt/root/Post-chroot.sh

arch-chroot /mnt /root/Post-chroot.sh

umount -a

sleep 2

echo -e "\nInstallation Complete.\n\nSystem will now reboot..."

sleep 10

reboot
