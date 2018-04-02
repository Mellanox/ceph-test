#/bin/bash -ex

. $(dirname $0)/colors_define.sh

if [ $# -lt 4 ] || [ "$1" == "-h" ]; then
        echo this script creates a ceph cluster usign ceph-deploy
        echo you must provide:
        echo -e "\t1. list of hosts"
        echo -e "\t2. list of mons"
        echo -e "\t3. ip of monitor"
	echo -e "\t4. rpm version name under /mswg/release/storage/ceph/"
        echo -e "\t5. clean only - optional parameter"
        echo -e "\t6. my_cluster - optional parameter"
        echo 'USAGE:' $0 '"host1 host2 host3" "mon1 mon2 mon3" selected_network latest [-c] [path_my_cluster]'
        echo 'example:' $0 '"h120 h121 h123 h123 h124" "h121 h124 h120" 11.130.1.00/16 latest [-c] [/.autodirect/mtrswgwork/user/my_cluster]'
        exit
fi

all_hosts="$1"
monitors="$2"
selected_network=$3
version=$4
my_cluster=$6
#optional parameter
if [ $# -ge 4 ]
then
   echo -e ${PURPLE} '** Call to clean cluster with parameters:' $all_hosts $my_cluster '**' ${NC};
  . $(dirname $0)/clean_cluster_rdma.sh "$all_hosts" "$my_cluster";
else
   echo -e ${PURPLE} '** Call without clean cluster **' ${NC}
fi

echo -e ${BLUE} '** Start creating new cluster **' ${NC}

build=${build:-latest}
#version=${version:-$build}
pdsh_hosts=`echo $all_hosts | tr \  ,`
rm -f hosts.txt
for host in $all_hosts; do echo $host >> hosts.txt; done

##### choose linux distribution util, set "installer" variable #######
/usr/bin/rpm -q -f /usr/bin/rpm >/dev/null 2>&1; if [ $? == 0 ] ; then os=centos; else os=ubuntu; fi

######  Install ceph-deploy ########
echo -e ${CYAN} installing ceph-deploy ${NC}

if [ "$os" == "ubuntu" ]; then
        echo -e ubuntu install
	DIR=`dirname $0`
        $DIR/install_ceph_deploy.sh;
else
        echo -e centos install
        sudo rpm -Uvh https://download.ceph.com/rpm-kraken/el7/noarch/ceph-deploy-1.5.36-0.noarch.rpm;
fi
echo -e ${CYAN} end of ceph-deploy install ${NC}


###### Install pdsh #######
if [ "$os" == "centos" ]; then installer=yum; else installer=apt-get; fi
echo -e  ${CYAN} install $installer pdsh ${NC} 
if ! dpkg -s pdsh &> /dev/null ; then sudo $installer install -y pdsh; fi


####INSTALL NEW CLUSTER####
echo -e ${CYAN} 'ceph-deploy install' ${NC}
ceph-deploy new --cluster-network=$selected_network --public-network=$selected_network $monitors
ceph-deploy --overwrite-conf install --repo-url=file:///mswg/release/storage/ceph/$version --gpg-url=file:///mswg/release/storage/ceph/$version/release.asc $all_hosts

#echo -e ${CYAN} 'update ceph.conf' ${NC}
#update ceph.conf
#cat << EOL >>  ceph.conf
#ms_type=async+rdma
#ms_async_rdma_device_name=mlx5_0
#ms_async_rdma_send_buffers=512
#ms_async_rdma_receive_buffers=512
#ms_cluster_type = async+rdma
#ms_public_type = async+rdma
#EOL

echo -e ${CYAN} 'install monitor and override ceph.conf' ${NC}
ceph-deploy --overwrite-conf mon create-initial
ceph-deploy --overwrite-conf admin $all_hosts
pdsh -R ssh -w $pdsh_hosts sudo chmod +rx /etc/ceph/ceph.client.admin.keyring

echo -e ${GREEN} install new RDMA cluster done ${NC}
