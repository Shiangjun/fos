#!/bin/bash
set -x
script_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

# This script sets up a Ubuntu host to be able to create the image by
# installing all of the necessary files. It assumes an EC2 host with
# passwordless sudo

# Install a bunch of packages we need

read -d '' PACKAGES <<EOT
bc
libtool-bin
gperf
bison
flex
texi2html
texinfo
help2man
gawk
libtool
build-essential
automake
libncurses5-dev
libz-dev
libglib2.0-dev
libpixman-1-dev
libunistring-dev
device-tree-compiler
qemu-user-static
binfmt-support
multistrap
git
lib32z1
lib32ncurses5
lib32stdc++6
libgnutls28-dev
libssl-dev
kpartx
nfs-common
zerofree
u-boot-tools
rpm2cpio
EOT
set -e

sudo apt-get install -y $PACKAGES

# Install up-to-date versions of crosstool and qemu
if [ -e tools ]; then
  rm -rf tools
fi

mkdir tools
cd tools/

CTVER=1.23.0
wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-$CTVER.tar.bz2
tar -xf crosstool-ng-$CTVER.tar.bz2
cd crosstool-ng-$CTVER/
./configure --prefix=/opt/crosstool-ng
make
sudo make install
cd ..

QEMVER=4.0.0
wget http://wiki.qemu-project.org/download/qemu-$QEMVER.tar.bz2
tar -xf qemu-$QEMVER.tar.bz2
cd qemu-$QEMVER
#patch -p 1 < $script_dir/qemu.patch
./configure --target-list=arm-linux-user,aarch64-linux-user --prefix=/opt/qemu --static --disable-gnutls
make -j 8
sudo make install
# Create the symlink that ubuntu expects
cd /opt/qemu/bin
sudo rm -rf qemu-arm-static qemu-aarch64-static
sudo ln -s qemu-arm qemu-arm-static
sudo ln -s qemu-aarch64 qemu-aarch64-static
cd ~

# Create gmake symlink to keep SDK happy
cd /usr/bin
if ! which gmake
then
  sudo ln -s make gmake
fi

#echo 'PATH=/opt/qemu/bin:/opt/crosstool-ng/bin:$PATH' >> ~/.profile

echo "Now install Vivado, SDx, and Petalinux."
echo "Re-login to  ensure the enviroment is properly set up."
