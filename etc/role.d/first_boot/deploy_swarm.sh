#!/bin/bash

swarm_role=__SWARM_ROLE__
if [[ "${swarm_role}" == "manager" ]]; then
    docker swarm init --advertise-addr __SWARM_MANAGER_IP__ | gawk '{if($0 ~ /docker swarm join --token/){print $5}}' > /root/docker_swarm.token
    scp -p /root/docker_swarm.token __SNOW_SERVER__:__SWARM_TOKEN_PATH__
    mkdir /etc/portainer
    docker stack deploy --compose-file /root/docker-compose.yml vote
fi


if [[ "${swarm_role}" == "worker" ]]; then
    mkdir /etc/portainer
    docker swarm join --token $(cat /root/docker_swarm.token) __SWARM_MANAGER_IP__:2377
fi
