#!/bin/bash 
parm="$1"

extras_repo_file="/etc/yum.repos.d/CentOS-extras.repo"
extras_repo="extras"
redhat_release_alt="CentOS Linux release 7.4.1708 (Core)"
release_f="/etc/redhat-release"
release_f_orig="/etc/redhat-release.orig"

function create_extras_repo() {
cat > ${extras_repo_file} <<-EOF
[extras]
name=CentOS-$releasever - Extras
baseurl=http://mirror.isoc.org.il/pub/centos/7.4.1708/extras/x86_64/
gpgcheck=0
EOF
}

function set_mlnx_env() {
	create_extras_repo
	yum clean all  &> /dev/null 
	if [ ! -e ${release_f_orig} ] ; then
		cp ${release_f} ${release_f_orig}
	fi
	echo "${redhat_release_alt}" > ${release_f}
	echo "#File was changed by ceph_mlnx_env.sh" >> ${release_f}
}

function unset_mlnx_env() {
	rm -f ${extras_repo_file}
	yum clean all &> /dev/null
	if [ -f ${release_f_orig} ] ; then
		cat ${release_f_orig} > ${release_f}
	fi
}

function status () {
	if [ -f ${release_f_orig} ] && [ "$(diff -q ${release_f} ${release_f_orig})" != "" ] ; then
		echo "${release_f} file changed"
	else
		echo "${release_f} NOT changed"
	fi

	if [ -f ${extras_repo_file} ] ; then
		echo "Extras repo file exists: ${extras_repo_file}"
	else
		echo "Extras repo file does NOT exists"
	fi
}

function usage() {
	echo
	echo
	echo "for status and help"
	echo "./ceph_mlnx_env.sh"
	echo "to set/unset server parameters to fit Mellanox restrictions "
	echo "./ceph_mlnx_env.sh [set|unset]"
	echo
}

if [ "$(whoami)" != "root" ] ; then
	echo "You have to be root to run this script"
	exit
fi

if [ "${parm}" == "set" ] ; then
	set_mlnx_env
elif [ "${parm}" == "unset" ] ; then
	unset_mlnx_env
elif [ "${parm}" == "" ] ; then
	status
	usage
else
	echo "Undefined parameter"
	usage
	exit
fi

