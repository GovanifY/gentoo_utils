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

fullversion=$(file /usr/src/linux | sed -e 's#.*linux-\(\)#\1#')
realversion=$(echo linux-$fullversion)
version=$(echo ${fullversion%%-*} | sed 's/\.0//')
mainversion=$(echo $version | cut -d '.' -f1-2)

#Nope this is totally NOT over-engineering
latest_version=$(eselect kernel list | grep linux | sed -e 's#.*linux-\(\)#\1#' | sort -V | sed -e '$!d' | sed s/\*// | awk '$0="linux-"$0')
#I swear everything else failed
if [ $(echo $realversion) == $(echo $latest_version) ]; then
    echo "Hey last kernel, gz m8, time to get a break"
    exit 1
fi
eselect kernel set $latest_version 
#We setup a free environment in case anything failed
fullversion=$(file /usr/src/linux | sed -e 's#.*linux-\(\)#\1#')
version=$(echo ${fullversion%%-*} | sed 's/\.0//')
mainversion=$(echo $version | cut -d '.' -f1-2)


echo "Using linux version" $version


#We compile the kernel and install it
#In some cases boot might not be booted if on another drive so let's do that
mount $BOOT
cp $BOOT/config /usr/src/linux/.config
make olddefconfig
make -j$(nproc) && make modules_install
make install
#We now need to rename our config to what we need and sign our files
system_map="$BOOT/System.map-$fullversion"
vmlinuz="$BOOT/vmlinuz-$fullversion"
config="$BOOT/config-$fullversion"
initr="$BOOT/initramfs-genkernel-$ARCH-$fullversion"
mv $system_map $BOOT/System.map
mv $vmlinuz $BOOT/vmlinuz
mv $config $BOOT/config
mv $initr $BOOT/initrd.img

#During make install linux appended a old, it becomes useless now
rm $BOOT/*.old
genkernel initramfs --install
