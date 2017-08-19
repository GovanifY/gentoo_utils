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
if [ $(echo $realversion) == $(echo $latest_version) ]; then
    echo "Hey last kernel, gz m8, time to get a break"
fi
echo $realversion
echo $latest_version

