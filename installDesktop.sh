#!/bin/sh
echo "FreeBSD: {" > /etc/pkg/FreeBSD.conf
echo "  url: \"pkg+http://pkg.FreeBSD.org/\${ABI}/quarterly\"," >> /etc/pkg/FreeBSD.conf
echo "  mirror_type: \"srv\"," >> /etc/pkg/FreeBSD.conf
echo "  signature_type: \"fingerprints\"," >> /etc/pkg/FreeBSD.conf
echo "  fingerprints: \"/usr/share/keys/pkg\"," >> /etc/pkg/FreeBSD.conf
echo "  enabled: no" >> /etc/pkg/FreeBSD.conf
echo "}" >> /etc/pkg/FreeBSD.conf

mkdir -p /usr/local/etc/pkg/repos
touch /usr/local/etc/pkg/repos/FreeBSD.conf

echo "FreeBSD: {" > /usr/local/etc/pkg/repos/FreeBSD.conf
echo "  url: \"pkg+http://mirrors.ustc.edu.cn/freebsd-pkg/\${ABI}/quarterly\"," >> /usr/local/etc/pkg/repos/FreeBSD.conf
echo "  mirror_type: \"srv\"," >> /usr/local/etc/pkg/repos/FreeBSD.conf
echo "  signature_type: \"fingerprints\"," >> /usr/local/etc/pkg/repos/FreeBSD.conf
echo "  fingerprints: \"/usr/share/keys/pkg\"," >> /usr/local/etc/pkg/repos/FreeBSD.conf
echo "  enabled: yes" >> /usr/local/etc/pkg/repos/FreeBSD.conf
echo "}" >> /usr/local/etc/pkg/repos/FreeBSD.conf

pkg update -f

freebsd-update fetch
freebsd-update install
pkg update -f

sysrc linux_enable=YES
sysrc dbus_enable=YES
sysrc hald_enable=YES

thFdesc=`cat /etc/fstab | grep fdesc`
if [ -z "$theFdesc" ]; then
	echo "fdesc	/dev/fd		fdescfs		rw	0	0" >> /etc/fstab
fi
thProc=`cat /etc/fstab | grep proc`
if [ -z "$theProc" ]; then
        echo "proc              /proc           procfs          rw      0" >> /etc/fstab
fi

autoBoot=`cat/boot/loader.conf | grep autoboot_delay`
if [ -z "$autoBoot" ]; then
	echo "autoboot_delay=\"1\"" >> /boot/loader.conf
fi

vga0=`pciconf -lv | grep vgapci0`
vga1=`pciconf -lv | grep vgapci1`
if [ "$vga0" -a "$vga1" ]; then
	pkg install -y drm-fbsd13-kmod
	#For Intel:
	echo "kld_list=\"i915kms\"" >> /etc/rc.conf
	#For amdgpu:
	#echo "kld_list=\"amdgpu\"" >> /etc/rc.conf
	#For radeonkms:
	#echo "kld_list=\"radeonkms\"" >> /etc/rc.conf
	pkg install -y xf86-video-intel
	pkg install -y libva-intel-driver
fi

theVga=`pciconf -lv | grep NVIDIA`
if [ -n "$theVga" ]; then
	pkg install -y nvidia-driver nvidia-settings nvidia-xconfig
	echo "kld_list=\"nvidia-modeset\"" >> /etc/rc.conf
fi

theVga=`pciconf -lv | grep VMware`
if [ -n "$theVga" ]; then
	pkg install -y xf86-video-vmware
	pkg install -y open-vm-tools
	sysrc vmware_guest_vmblock_enable=YES
	sysrc vmware_guest_vmhgfs_enable=YES
	sysrc vmware_guest_vmmemctl_enable=YES
	sysrc vmware_guest_vmxnet_enable=YES
	sysrc vmware_guest_enable=YES
	sysrc fuse_load=YES
fi

pkg install -y xorg
pkg install -y wqy-fonts
zh=`cat /etc/csh.cshrc | grep zh_CN`
if [ -z "$zh" ]; then
	echo  >> /etc/csh.cshrc
	echo "setenv LANG zh_CN.UTF-8" >> /etc/csh.cshrc
	echo "setenv LANGUAGE zh_CN.UTF-8"  >> /etc/csh.cshrc
	echo "setenv LC_ALL zh_CN.UTF-8"  >> /etc/csh.cshrc
	echo  >> /etc/csh.cshrc
fi

theDesktop=-1
until [ $theDesktop -ge 0 -a $theDesktop -le 3 ]
do
	clear
	echo
	echo
	echo
	echo "          Select the desktop to install. "
	echo "                1. Gnome3"
	echo "                2. Xfce4"
	echo "                3. KDE5"
	echo "                0. Exit"
	read -p "          Please input 1, 2, 3 or 0 and press \"Enter\" :  " theDesktop
done

if [ $theDesktop -eq 1 ]; then
	pkg install -y zh-ibus-rime zh-rime-wubi
	theIbus=`cat /etc/csh.cshrc | grep ibus`
	if [ -z "$theIbus" ]; then
		echo "setenv XIM ibus" >> /etc/csh.cshrc
		echo "setenv GTK_IM_MODULE ibus" >> /etc/csh.cshrc
		echo "setenv QT_IM_MODULE ibus" >> /etc/csh.cshrc
		echo "setenv XMODIFIERS @im=ibus" >> /etc/csh.cshrc
		echo "setenv XIM_PROGRAM ibus-daemon" >> /etc/csh.cshrc
		echo "setenv XIM_ARGS \"--daemonize --xim\"" >> /etc/csh.cshrc
	fi

	pkg install -y gnome3
	sysrc gdm_enable=YES
	sysrc gnome_enable=YES

	zh=`cat /usr/local/etc/gdm/locale.conf | grep zh_CN`
	if [ -z "$zh" ]; then
	       echo "LANG=\"zh_CN.UTF-8\"" > /usr/local/etc/gdm/locale.conf
	       echo "LC_CTYPE=\"zh_CN.UTF-8\"" >> /usr/local/etc/gdm/locale.conf
	       echo "LC_MESSAGES=\"zh_CN.UTF-8\"" >> /usr/local/etc/gdm/locale.conf
	       echo "LC_ALL=\"zh_CN.UTF-8\""  >> /usr/local/etc/gdm/locale.conf
	fi

	userList=`ls /home`
	for user in $userList
	do
		mkdir -p /home/$user/.config/ibus/rime/
		chown -R $user:$user /home/$user/.config
		touch  /home/$user/.config/ibus/rime/default.custom.yaml
		chown -R $user:$user /home/$user/.config/ibus/rime/default.custom.yaml
		echo "patch:" >  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "    \"menu/page_size\": 6" >>  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "" >>  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "    schema_list:" >>  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "        - schema: wubi86" >>  /home/$user/.config/ibus/rime/default.custom.yaml
	done
fi

if [ $theDesktop -eq 2 ]; then

	pkg install -y zh-ibus-rime zh-rime-wubi
	theIbus=`cat /etc/csh.cshrc | grep ibus`
	if [ -z "$theIbus" ]; then
		echo "setenv XIM ibus" >> /etc/csh.cshrc
		echo "setenv GTK_IM_MODULE ibus" >> /etc/csh.cshrc
		echo "setenv QT_IM_MODULE ibus" >> /etc/csh.cshrc
		echo "setenv XMODIFIERS @im=ibus" >> /etc/csh.cshrc
		echo "setenv XIM_PROGRAM ibus-daemon" >> /etc/csh.cshrc
		echo "setenv XIM_ARGS \"--daemonize --xim\"" >> /etc/csh.cshrc
	fi

	pkg install -y xfce
	touch ~/.xinitrc
	echo "/usr/local/etc/xdg/xfce4/xinitrc" > ~/.xinitrc

	pkg install -y slim slim-themes
	sysrc slim_enable=YES

	userList=`ls /home`
	for user in $userList
	do
		touch /home/$user/.xinitrc
		chown -R $user:$user /home/$user/.xinitrc
		echo "/usr/local/etc/xdg/xfce4/xinitrc" > /home/$user/.xinitrc
		mkdir -p /home/$user/.config/ibus/rime/
		chown -R $user:$user /home/$user/.config
		touch  /home/$user/.config/ibus/rime/default.custom.yaml
		chown -R $user:$user /home/$user/.config/ibus/rime/default.custom.yaml
		echo "patch:" >  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "    \"menu/page_size\": 6" >>  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "" >>  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "    schema_list:" >>  /home/$user/.config/ibus/rime/default.custom.yaml
		echo "        - schema: wubi86" >>  /home/$user/.config/ibus/rime/default.custom.yaml
	done

	pkg install -y xfce4-pulseaudio-plugin
fi

if [ $theDesktop -eq 3 ]; then
	pkg install -y kde5
	pkg install -y sddm
	sysrc sddm_enable=YES

	pkg install -y zh-fcitx zh-fcitx-configtool fcitx-qt5 fcitx-m17n
	thefcitx=`cat /etc/csh.cshrc | grep fcitx`
	if [ -z "$thefcitx" ]; then
	        echo "setenv QT4_IM_MODULE fcitx" >> /etc/csh.cshrc
	        echo "setenv GTK_IM_MODULE fcitx" >> /etc/csh.cshrc
	        echo "setenv QT_IM_MODULE fcitx" >> /etc/csh.cshrc
	        echo "setenv GTK2_IM_MODULE fcitx" >> /etc/csh.cshrc
	        echo "setenv GTK3_IM_MODULE fcitx" >> /etc/csh.cshrc
	        echo "setenv XMODIFIERS @im=fcitx" >> /etc/csh.cshrc
	fi

	userList=`ls /home`
	for user in $userList
	do
		if [ ! -e /home/$user/.config/autostart ]; then
			mkdir -p /home/$user/.config/autostart
			chmod 755 /home/$user/.config/autostart
			chown -R $user:$user /home/$user/.config
		fi
		cp /usr/local/share/applications/fcitx.desktop /home/$user/.config/autostart/
		chmod 755 /home/$user/.config/autostart/fcitx.desktop
		chown -R $user:$user /home/$user/.config
	done
fi

if [ $theDesktop -ge 1 -a $theDesktop -le 3 ]; then
	pkg install -y firefox-esr
	reboot
fi
