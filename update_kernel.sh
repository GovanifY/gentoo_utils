#To go back at the end to free it
WORKDIR=$(pwd)
#We need that for gentoo genkernel
ARCH="x86_64"
#And this for boot, but this shouldn't change
BOOT="/boot"

# Make sure only root can run this script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#We setup a free environment in case anything failed
rm -rf deblob deblob.sign deblob-check deblob-check.sign initramfs initrd.img &> /dev/null
echo "Please verify that the given kernel (using eselect kernel list) is correctly set up"
fullversion=$(file /usr/src/linux | sed -e 's#.*linux-\(\)#\1#')
version=$(echo ${fullversion%%-*} | sed 's/\.0//')
mainversion=$(echo $version | cut -d '.' -f1-2)
echo "Using linux version" $version
read

#Downloading deblobbing scripts
wget "https://linux-libre.fsfla.org/pub/linux-libre/releases/$version-gnu/deblob-$mainversion" -O deblob || { echo 'Could not download deblobbing scripts!' ; exit 1; }
wget "https://linux-libre.fsfla.org/pub/linux-libre/releases/$version-gnu/deblob-$mainversion.sign" -O deblob.sign || { echo 'Could not download deblobbing scripts!' ; exit 1; }
wget "https://linux-libre.fsfla.org/pub/linux-libre/releases/$version-gnu/deblob-check" -O deblob-check || { echo 'Could not get download deblobbing scripts!' ; exit 1; }
wget "https://linux-libre.fsfla.org/pub/linux-libre/releases/$version-gnu/deblob-check.sign" -O deblob-check.sign || { echo 'Could not download deblobbing scripts!' ; exit 1; }
chmod 744 deblob deblob-check
echo "Verifying signature of scripts"
gpg --verify deblob.sign deblob || { echo 'Failed to verify signature of deblobbing scripts!' ; exit 1; }
gpg --verify deblob-check.sign deblob-check || { echo 'Failed to verify signature of deblobbing scripts!' ; exit 1; }

#We deblob the kernel
if [[ $(cat /usr/src/linux/Makefile | grep EXTRAVERSION | grep gnu) ]]; then
    echo "Kernel is already deblobbed! Moving on..."
    cd /usr/src/linux
else
    present_python=$(eselect python list | grep [1] | sed -e 's#.*p\(\)#\1p#')
    echo "We are now changing python interpreter as deblobbing scripts use 2.7, be wary that if the script fail you might have to change manually the interpreter used!"
    eselect python set python2.7 || { echo 'Failed to set python2.7 as an interpreter!' ; exit 1; }
    cp deblob deblob-check /usr/src/linux
    cd /usr/src/linux
    ./deblob || { echo 'Failed to deblob the kernel!' ; exit 1; }
    eselect python set $present_python || { echo '...Failed to set back original python interpreter...? The hell ($present_python)' ; exit 1; }
fi

#We compile the kernel and install it
#In some cases boot might not be booted if on another drive so let's do that
mount $BOOT
gpg --verify $BOOT/config.sig $BOOT/config || { echo 'Failed to verify signature of linux kernel config! THIS IS A RED FLAG' ; exit 1; }
cp $BOOT/config /usr/src/linux/.config
make olddefconfig
make -j$(nproc) && make modules_install
make install
#We now need to rename our config to what we need and sign our files
system_map="$BOOT/System.map-$fullversion-gnu"
vmlinuz="$BOOT/vmlinuz-$fullversion-gnu"
config="$BOOT/config-$fullversion-gnu"
mv $system_map $BOOT/System.map
mv $vmlinuz $BOOT/vmlinuz
mv $config $BOOT/config
rm $BOOT/System.map.sig
rm $BOOT/vmlinuz.sig
rm $BOOT/config.sig
gpg --detach-sign $BOOT/System.map
gpg --detach-sign $BOOT/vmlinuz
gpg --detach-sign $BOOT/config

#During make install linux appended a old, it becomes useless now
rm $BOOT/*.old
genkernel initramfs --install
initr="$BOOT/initramfs-genkernel-$ARCH-$fullversion-gnu"
#mv $initr $BOOT/initrd.img
cd $WORKDIR

#We need to edit the automatic initramfs to add our keyfile
#This given keyfile prevents to type LUKS password twice
#(GRUB decryption followed by initramfs)
mv $initr initrd.img.xz
unxz initrd.img.xz
mkdir initramfs && cd initramfs
mkdir etc && cp /etc/keyfile etc/

find . -print | cpio --quiet -o -H newc --append -F ../initrd.img
cd ..
xz -e --check=none -z -f -9 initrd.img

rm -rf initramfs

#We sign and we're done for
mv initrd.img.xz $BOOT/initrd.img
rm $BOOT/initrd.img.sig
gpg --detach-sign $BOOT/initrd.img
rm -rf initrd.img deblob-check deblob deblob-check.sign deblob.sign
