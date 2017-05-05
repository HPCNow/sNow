#!/bin/bash
torque_version=__TORQUE_VERSION__
mkdir /usr/lib/systemd/system/
uname -n > /var/spool/torque/server_name
# trqauthd
cd /root/torque/${torque_version}
cp contrib/systemd/trqauthd.service /usr/lib/systemd/system/
systemctl enable trqauthd.service
systemctl start trqauthd.service
if [[ -e /etc/torque.conf ]]; then 
    /usr/local/bin/qmgr -c < /etc/torque.conf
else
    cd /root/torque/${torque_version}
    bash torque.setup root
fi
qterm
# PBS Server
cp contrib/systemd/pbs_server.service /usr/lib/systemd/system/
systemctl enable pbs_server.service
systemctl start pbs_server.service
# PBS Sched
sleep 10
cp contrib/systemd/pbs_sched.service /usr/lib/systemd/system/
qmgr -c "set server scheduling = True"
systemctl enable pbs_sched.service
systemctl start pbs_sched.service
