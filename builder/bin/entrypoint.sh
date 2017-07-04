#!/bin/bash
set -eux

wait_for_koji_hub_to_start() {
    while true; do
        echo "Waiting for koji-hub to start..."
        hubstart=$(curl -X GET http://koji-hub/)
        #echo $hubstart
        if [ "x$hubstart" != "x" ]; then
            echo "koji-hub started:"
            break
        fi
        sleep 5
    done
}

install_builder() {
    if [ -d /opt/koji/noarch ]; then
        echo "Installing from /opt/koji/noarch"
        yum -y localinstall /opt/koji/noarch/python2-koji-1*.rpm
        yum -y localinstall /opt/koji/noarch/koji-1*.rpm
        yum -y localinstall /opt/koji/noarch/koji-hub-*.rpm
        yum -y localinstall /opt/koji/noarch/koji-builder*.rpm
    else
        echo "No koji RPM to install! Installing from EPEL"
        yum -y install epel-release
        yum -y install koji-builder
    fi
}

configure_builder() {
    echo "Configure builder to connect to koji-hub"

    mkdir -p /etc/kojid
    cp /opt/koji-clients/kojibuilder/client.crt /etc/kojid/kojibuilder.crt
    cp /opt/koji-clients/kojibuilder/clientca.crt /etc/kojid/koji_client_ca_cert.crt
    cp /opt/koji-clients/kojibuilder/serverca.crt /etc/kojid/koji_server_ca_cert.crt

install_osbs_updates() {
    curl -kL https://copr.devel.redhat.com/coprs/vrutkovs/osbs/repo/rhel-6/vrutkovs-osbs-rhel-6.repo -o /etc/yum.repos.d/osbs-updates.repo
    echo -e "\nsslverify=0" >> /etc/yum.repos.d/osbs-updates.repo
    yum install -y osbs-client koji-containerbuild koji-containerbuild-builder
}

install_osbs_client() {
    echo "Installing OSBS Client"

    OSBS_SOURCE=${OSBS_REMOTE:-https://github.com/projectatomic/osbs-client.git}
    OSBS_GITBRANCH=${OSBS_BRANCH:-master}

    rm -rf ~/osbs-client
    git clone $OSBS_SOURCE ~/osbs-client
    cd ~/osbs-client
    git checkout $OSBS_GITBRANCH
    git rev-parse HEAD
    yum install -y python-pip
    pip install -U setuptools
    pip install -r requirements.txt
    python setup.py install
    mkdir -p /usr/share/osbs
    cp inputs/* /usr/share/osbs
}

install_kcb() {
    KCB_SOURCE=${KCB_REMOTE:-https://github.com/release-engineering/koji-containerbuild.git}
    KCB_GITBRANCH=${KCB_BRANCH:-develop}

    rm -rf ~/koji-containerbuild
    git clone $KCB_SOURCE ~/koji-containerbuild
    cd ~/koji-containerbuild
    git checkout $KCB_GITBRANCH
    git rev-parse HEAD
    # Remove install_requires
    sed -i -e '/"koji",/d' -e '/"osbs",/d' setup.py
    python setup.py install
    cp koji_containerbuild/plugins/builder_containerbuild.py /usr/lib/koji-builder-plugins/builder_containerbuild.py
}

update_buildroot(){
    if [ -f /opt/osbs/osbs.conf ]; then
      cp /opt/osbs/osbs.conf /etc/osbs.conf
    fi

    BUILDROOT_INITIAL_IMAGE=${BUILDROOT_INITIAL_IMAGE:-}
    if [ -n "${BUILDROOT_INITIAL_IMAGE}" ]; then
      sed -i "s,build_image = .*,build_image = $BUILDROOT_INITIAL_IMAGE,g" /etc/osbs.conf
    fi

}

# delete line starting with allowed_scms=
cp /etc/kojid/kojid.conf /etc/kojid/kojid.conf.example
sed -i.bak '/topurl=/d' /etc/kojid/kojid.conf
sed -i.bak '/server=/d' /etc/kojid/kojid.conf
sed -i.bak '/allowed_scms=/d' /etc/kojid/kojid.conf

    cat <<EOF >> /etc/kojid/kojid.conf

; The URL for the xmlrpc server
server=https://koji-hub/kojihub

; the username has to be the same as what you used with add-host
; in this example follow as below
user = kojibuilder

; The URL for the file access
topurl=http://koji-hub/kojifiles

; The directory root for temporary storage
workdir=/tmp/koji

; The directory root where work data can be found from the koji hub
topdir=/mnt/koji

;client certificate
; This should reference the builder certificate we created on the kojihub CA, for kojibuilder
; ALSO NOTE: This is the PEM file, NOT the crt
cert = /etc/kojid/kojibuilder.crt

;certificate of the CA that issued the client certificate
ca = /etc/kojid/koji_client_ca_cert.crt

;certificate of the CA that issued the HTTP server certificate
serverca = /etc/kojid/koji_server_ca_cert.crt

PluginPath = /usr/lib/koji-builder-plugins
Plugins = builder_containerbuild
allowed_scms=pkgs.devel.redhat.com:/*:no git.engineering.redhat.com:/*:no dist-git-qa.app.eng.bos.redhat.com:/*:no

EOF
    #diff /etc/kojid/kojid.conf.example /etc/kojid/kojid.conf

    koji -c /opt/koji-clients/kojiadmin/config edit-host --capacity=${CAPACITY:8} kojibuilder
}


start_ssh() {
    local RUN_IN_FOREGROUND=$1
    echo "You can connect directly by running"
    echo "      docker exec -ti koji-hub /bin/bash"
    echo "Starting ssh on ${IP} (use ssh root@${IP} with password mypassword"
    if [ "$RUN_IN_FOREGROUND" == "RUN_IN_FOREGROUND" ]; then
        ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key
        ssh-keygen -t dsa -N '' -f /etc/ssh/ssh_host_dsa_key
        /usr/sbin/sshd -D
    else
#        /etc/init.d/sshd start
        /usr/sbin/sshd
    fi
}

start_builder() {
    koji -c /opt/koji-clients/kojiadmin/config add-host-to-channel kojibuilder container --new || true

    local RUN_IN_FOREGROUND=${1:-}
    echo "Starting koji builder on ${IP}"
    if [ "$RUN_IN_FOREGROUND" == "RUN_IN_FOREGROUND" ]; then
        /usr/sbin/kojid -d -v -f --force-lock
    else
        #/etc/init.d/kojid start
	/usr/sbin/kojid
    fi
}

set -x
IP=$(find-ip.py)

wait_for_koji_hub_to_start
install_builder
configure_builder
if [ "${USE_PIP}" == "1" ]; then
    install_osbs_client
    install_kcb
else
    install_osbs_updates
fi
update_buildroot
#start_ssh
start_builder "RUN_IN_FOREGROUND"
