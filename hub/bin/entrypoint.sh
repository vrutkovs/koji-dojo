#!/bin/bash
set -x

# add koji-db to hosts if not present
KOJI_DB="${KOJI_DB:-koji-db}"
if grep -q -v "koji-db" /etc/hosts; then
    KOJI_DB_IP=$(getent hosts $KOJI_DB | awk '{ print $1 }')
    echo ${KOJI_DB_IP} koji-db >> /etc/hosts
fi

set -ex

build-koji.sh
setup.sh

mkdir -p /usr/lib/koji-hub-plugins
curl https://raw.githubusercontent.com/release-engineering/koji-containerbuild/master/koji_containerbuild/plugins/hub_containerbuild.py -o /usr/lib/koji-hub-plugins/hub_containerbuild.py

IP=$(find-ip.py)

# add koji-hub to hosts if not present
if grep -q -v "koji-hub" /etc/hosts; then echo ${IP} koji-hub >> /etc/hosts; fi

echo "Starting ssh on ${IP} (use ssh root@${IP} with password mypassword"
#/etc/init.d/sshd start
/usr/sbin/sshd 
echo "You can connect directly by running"
echo "      docker exec -ti koji-hub /bin/bash"
echo "Starting HTTPd on ${IP}"
httpd -D FOREGROUND
