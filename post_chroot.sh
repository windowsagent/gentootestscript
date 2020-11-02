#TODO
#Replace all the echo with printf
#source /etc/profile
#export PS1="(chroot) ${PS1}"

cd gentootestscript-master
scriptdir=$(pwd)
cd ..
LIGHTGREEN='\033[1;32m'
LIGHTBLUE='\033[1;34m'
printf ${LIGHTBLUE}"Enter the username for your NON ROOT user\n"
#There is a possibility this won't work since the handbook creates a user after rebooting and logging as root
read username
username="${username,,}"
printf ${LIGHTBLUE}"Do you want to migrate openssl to libressl?\n"
read sslmigrateanswer
printf ${LIGHTBLUE}"Enter the Hostname you want to use\n"
read hostname


mount /dev/sda1 /boot
printf "mounted boot\n"
emerge-webrsync
printf "webrsync complete\n"

if [ $sslmigrateanswer = "yes" ]; then
	printf "beginning openssl to libressl migration\n"
	emerge -uvNDq world
	emerge gentoolkit
	equery d openssl
	equery d libressl
	printf "openssl and libressl dependencies considered\n"
	echo 'USE="${USE} libressl"' >> /etc/portage/make.conf
	printf "added libressl use flag to /portage/make.conf\n"
	echo 'CURL_SSL="libressl"' >> /etc/portage/make.conf
	mkdir -p /etc/portage/profile
	printf "-libressl\n" >> /etc/portage/profile/use.stable.mask
	echo "dev-libs/openssl" >> /etc/portage/package.mask
	echo "dev-libs/libressl" >> /etc/portage/package.accept_keywords
	emerge -f libressl
	emerge -C openssl
	echo "removed openssl"
	emerge -1q libressl
	echo "installed libressl"
	emerge -1q openssh wget python:2.7 python:3.4 iputils
else
	printf "using default openssl\n"
fi

printf "preparing to do big emerge\n"

emerge --verbose --update --deep --newuse @world
printf "big emerge complete\n"
printf "America/New_York\n" > /etc/timezone
emerge --config sys-libs/timezone-data
printf "timezone data emerged\n"
en_US.UTF-8 UTF-8
printf "en_US.UTF-8 UTF-8\n" >> /etc/locale.gen
locale-gen
printf "script complete\n"
eselect locale set 4
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

#Installs the kernel
emerge sys-kernel/gentoo-kernel-bin

#enables DHCP
sed -i -e "s/localhost/$hostname/g" /etc/conf.d/hostname
emerge --noreplace net-misc/netifrc
printf "config_enp0s3=\"dhcp\"\n" >> /etc/conf.d/net
printf "/dev/sda1\t\t/boot\t\text4\t\tdefaults,noatime\t0 2\n" >> /etc/fstab
printf "/dev/sda2\t\t/\t\text4\t\tnoatime\t0 1\n" >> /etc/fstab
cd /etc/init.d
ln -s net.lo net.enp0s3
rc-update add net.enp0s3 default
printf "dhcp enabled\n"
emerge app-admin/sysklogd
emerge app-admin/sudo
rm -rf /etc/sudoers
cd $scriptdir
cp sudoers /etc/
printf "installed sudo and enabled it for wheel group\n"
rc-update add sysklogd default
emerge sys-apps/mlocate
emerge net-misc/dhcpcd

#installs grub
emerge --verbose sys-boot/grub:2
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
useradd -m -G users,wheel,audio -s /bin/bash $username
cd ..
printf "cleaning up\n"
mv gentootestscript-master.zip /home/$username
rm -rf /gentootestscript-master
stage3=$(ls stage3*)
rm -rf $stage3
printf "preparing to exit the system, run the following commands and then reboot without the CD\n"
printf "you should now have a working Gentoo installation, dont forget to set your root and user passwords!\n"
printf ${LIGHTGREEN}"passwd\n"
printf ${LIGHTGREEN}"passwd %s\n" $username
printf ${LIGHTGREEN}"exit\n"
printf ${LIGHTGREEN}"cd\n"
printf ${LIGHTGREEN}"umount -l /mnt/gentoo/dev{/shm,/pts,}\n"
printf ${LIGHTGREEN}"umount -R /mnt/gentoo\n"
printf ${LIGHTGREEN}"reboot\n"
rm -rf /post_chroot.sh
exit
