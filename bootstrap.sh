#! /bin/sh

export LANG=C
export LC_ALL=C


# -- Packages to install.

PACKAGES='
dhcpcd5
user-setup
localechooser-data
cifs-utils
casper
lupin-casper
nomad-desktop
'


# # -- Make /bin, /sbin and /usr/sbin, symlinks to /usr/bin.
# 
# # make copies of commands before moving
# cp /bin/mv /usr/bin/mv_clone
# cp /bin/ln /usr/bin/ln_clone
# 
# # copy contents to usr/bin, delete dirs and create symlinks
# mv_clone /bin/* /usr/bin
# rm -rf /bin
# ln_clone -sv /usr/bin /bin
# 
# mv_clone /sbin/* /usr/bin
# rm -rf /sbin
# ln_clone -sv /usr/bin /sbin
# 
# mv_clone /usr/sbin/* /usr/bin
# rm -rf /usr/sbin
# ln_clone -sv /usr/bin /usr/sbin
# 
# # delete copies of commands
# rm /usr/bin/mv_clone /usr/bin/ln_clone


# -- Install basic packages.

apt -qq update
apt -yy -qq install apt-transport-https wget ca-certificates gnupg2 apt-utils --no-install-recommends > /dev/null


# -- Use optimized sources.list. The LTS repositories are used to support the KDE Neon repository since these
# -- packages are built against the latest LTS release of Ubuntu.

cp /configs/sources.list /etc/apt/sources.list

wget -q https://archive.neon.kde.org/public.key -O neon.key
echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c &&
	apt-key add neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
echo b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key | sha256sum -c &&
	apt-key add nxos.key

rm neon.key
rm nxos.key


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package
# -- avoiding recommended packages.

apt -qq update
apt -yy install $(echo $PACKAGES | tr '\n' ' ') --no-install-recommends > /dev/null
apt -yy -qq install --only-upgrade base-files=10.4+nxos > /dev/null
apt -qq clean
apt -qq autoclean


# -- Install AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous/znx
https://github.com/UriHerrera/storage/raw/master/ungoogled-chromium_69.0.3497.100-2_linux.AppImage
https://github.com/anupam-git/vlc-appimage/releases/download/continuous/VLC_media_player-x86_64.AppImage
https://libreoffice.soluzioniopen.com/stable/fresh/LibreOffice-fresh.basic-x86_64.AppImage
'

mkdir /Applications

for x in $(echo $APPS | tr '\n' ' '); do
	wget -qP /Applications $x
done

chmod +x /Applications/*


# -- Add znx-gui.

cp /configs/znx-gui.desktop /usr/share/applications
wget -q https://raw.githubusercontent.com/Nitrux/znx-gui/master/znx-gui -O /bin/znx-gui
chmod +x /bin/znx-gui


# -- Install the latest stable kernel.

kfiles='
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.14/linux-headers-4.18.14-041814_4.18.14-041814.201810130431_all.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.14/linux-headers-4.18.14-041814-generic_4.18.14-041814.201810130431_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.14/linux-image-unsigned-4.18.14-041814-generic_4.18.14-041814.201810130431_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.14/linux-modules-4.18.14-041814-generic_4.18.14-041814.201810130431_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel
rm -r latest_kernel


# -- Install Maui Apps Debs.

mauipkgs='
https://raw.githubusercontent.com/UriHerrera/storage/master/mauikit-framework_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/vvave_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/pix_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/index_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/buho_0.1-1_amd64.deb
'

mkdir maui_debs

for x in $mauipkgs; do
	wget -q -P maui_debs $x
done

dpkg -iR maui_debs
rm -r maui_debs


# -- Install Software Center Maui port.

nxsc='
https://raw.githubusercontent.com/UriHerrera/storage/master/libappimageinfo_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/nx-software-center_2.3-1_amd64.deb
'

mkdir nxsc_deps

for x in $nxsc; do
	wget -q -P nxsc_deps $x
done
dpkg --force-all -iR nxsc_deps
rm -r nxsc_deps


# -- For now, the software center, libappimage and libappimageinfo provide the same library and to install each one it must be overriden each time.

ln -sv /usr/lib/x86_64-linux-gnu/libbfd-2.30-multiarch.so /usr/lib/x86_64-linux-gnu/libbfd-2.31.1-multiarch.so
ln -sv /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0
ln -sv /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0

# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
# -- firejail should be automatically used by the daemon to sandbox AppImages.

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-git189b800.travis42_amd64.deb
'

mkdir appimaged_deb

for x in $appimgd; do
	wget -q -P appimaged_deb $x
done
dpkg -iR appimaged_deb
rm -r appimaged_deb


# -- Add /Applications to $PATH.

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers

# -- Add config for SDDM.

cp /configs/sddm.conf /etc


# -- Modify the initramfs code.

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
cat /configs/update-image >> /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan
update-initramfs -u

# -- Fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842

cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/

# -- Create /Applications dir for users. This dir "should" be created by the Software Center.
# -- Downloading AppImages with the SC will fail if this dir doesn't exist.

mkdir /etc/skel/Applications

# -- Move AppImages to the user /Applications dir.

ln -sv /Applications/*.AppImage /etc/skel/Applications
