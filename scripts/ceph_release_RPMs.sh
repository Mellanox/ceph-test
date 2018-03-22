#/bin/bash -ex

#if [ $# -lt 2 ] || [ "$1" == "-h" ]; then
#        echo this script releases RPMs from local ceph directory
#        echo you must provide:
#        echo -e "\t1. user name from your email, e.g. moshe@mellanox.com"
#        echo -e "\t2. latest version under http://gitbuilder.ceph.com/ceph-rpm-centos7-x86_64-basic/ref/"
#        echo 'USAGE:' $0 '"username" "v11.11.11"'
#        echo 'example:' $0 '"moshe" "v11.2.0"'
#        exit
#fi

OPTS=$(getopt -o hv:d:r: --long help,version:,destination:,rpmtop: -- "$@")
eval set -- "$OPTS"

HELP=false
DESTINATION=${DESTINATION:-"/auto/mswg/release/storage/ceph"}
USER=${SUDO_USER:-`whoami`}
VER=""
RPMTOP=${RPMTOP:-`sudo -u $USER rpm --eval "%{_topdir}"`}

echoerr()
{
	>&2 echo "$@"
	exit 1
}

while true; do
	case "$1" in
		-v | --version ) VER=$2; shift; shift ;;
		-d | --destination ) DESTINATION=$2; shift; shift ;;
		-r | --rpmtop ) RPMTOP=$2; shift; shift ;;
		-h | --help )    HELP=true; shift ;;
		-- ) shift; break ;;
		* ) break ;;
	  esac
done

if [[ $HELP == true ]]; then
	echo "This script releases RPMs from local ceph directory"
	echo "Default destination folder: $DESTINATION"
	echo "Owner of this folder is \"ceph-release\" user"
fi

if [[ -z $VER ]]; then
	git rev-parse --is-inside-work-tree &&  VER=`git describe`               # example: v11.1.0-6089-g7a3e505

	if [[ -z $VER ]]; then
		echoerr "Either run the script from git repository or provide version number"
	fi
fi

if [[ ! -d ${DESTINATION} ]]; then
	echoerr "${DESTINATION} doesn't exist"
fi

if [[ ! -d ${RPMTOP} ]]; then
	echoerr "${RPMTOP} doesn't exist"
fi

TARGET=${DESTINATION}/rpm-$VER

echo "Source RPM top dir: $RPMTOP"
echo "Version: $VER"
echo "Destination: ${DESTINATION}"
echo "Target: ${TARGET}"
echo "User: $USER"

exit 1

function create_release
{
	mkdir -p $TARGET/noarch
	wget --directory-prefix=$TARGET/noarch https://download.ceph.com/rpm-luminous/el7/noarch/ceph-release-1-0.el7.noarch.rpm

	createrepo $TARGET/noarch
	#gpg --detach-sign --armor $TARGET/noarch/repodata/repomd.xml # if this fails you probably don't have a gpg key, see prerequisites above

	cp -r $RPMTOP/RPMS/x86_64 $RPMTOP/SRPMS/ $TARGET
	createrepo $TARGET/SRPMS
	rpm --addsign $TARGET/x86_64/*.rpm
	createrepo $TARGET/x86_64
	#sudo -u ceph-release gpg --detach-sign --armor $TARGET/x86_64/repodata/repomd.xml

	#gpg --armor --export $user@mellanox.com > $TARGET/release.asc
	#sudo -u ceph-release gpg --armor --export 'sashakot <sashakot@mellanox.com>' > $TARGET/release.asc
}

create_release
