#!/bin/sh

# edited by: Dobby233Liu [15816141883#qq.com]
set -ex


# step 1: 下载源代码并解压

# def: 4.19.12
KERNEL_VERSION=4.20.3
# def: 1.29.3
BUSYBOX_VERSION=1.30.0
# def: 6.03
SYSLINUX_VERSION=6.03
# 下载
wget -O kernel.tar.xz http://kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VERSION}.tar.xz
wget -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
wget -O syslinux.tar.xz http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VERSION}.tar.xz
# 解压
tar -xvf kernel.tar.xz
tar -xvf busybox.tar.bz2
tar -xvf syslinux.tar.xz

# step 2: 准备iso储存文件夹

mkdir isoimage

# step 3: 编译busybox

# 不必解释
cd busybox-${BUSYBOX_VERSION}
# 清一下工程，然后加一个默认配置文件
make distclean defconfig
# 必须以static（静态）模式编译，否则会kernel panic
sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" .config
# 安装到_install文件夹
make busybox install
cd _install

# step 4: 创建initramfs？

# linuxrc没用
rm -f linuxrc
# 创建几个基础文件夹
mkdir dev proc sys
# init（初始化）脚本
echo '#!/bin/sh' > init
echo 'dmesg -n 1' >> init
echo 'mount -t devtmpfs none /dev' >> init
echo 'mount -t proc none /proc' >> init
echo 'mount -t sysfs none /sys' >> init
echo 'setsid cttyhack /bin/sh' >> init
# 加上可执行权限
chmod +x init
# 改权限并打包rootfs
find . | cpio -R root:root -H newc -o | gzip > ../../isoimage/rootfs.gz

# step 5: 编译 linux 内核

# 也不用解释了
cd ../../linux-${KERNEL_VERSION}
# 清一下工程，然后加一个默认配置文件，再编译bzImage
make mrproper defconfig bzImage
# 复制bzImage到isoimage文件夹
cp arch/x86/boot/bzImage ../isoimage/kernel.gz

# step 6: ISOLinux

cd ../isoimage
cp ../syslinux-${SYSLINUX_VERSION}/bios/core/isolinux.bin .
cp ../syslinux-${SYSLINUX_VERSION}/bios/com32/elflink/ldlinux/ldlinux.c32 .
echo 'default kernel.gz initrd=rootfs.gz' > ./isolinux.cfg

# step 7: 制作iso
xorriso \
  -as mkisofs \
  -o ../minimal_linux_live.iso \
  -b isolinux.bin \
  -c boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  ./

# final step: cd出去

cd ..

set +ex
