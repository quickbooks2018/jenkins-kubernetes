#!/bin/bash

####################
# Jenkins Deployment 
####################

docker network create jenkins --attachable

docker volume create jenkins

###################################
# Build docker images with jenkins
###################################
docker run --name jenkins --network jenkins -w /var/jenkins_home -id -v jenkins:/var/jenkins_home -p 80:8080 -v $(which docker):/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped jenkins/jenkins:lts

echo "Waiting jenkins to launch on 80.."

while ! nc -vz localhost 80; do
  sleep 0.1 # wait for 1/10 of the second before check again
done
echo "Jenkins launched"


###########################
# Docker Socket Permissions
###########################
cat <<JENkINS > jenkins-permissions.sh
#!/bin/bash
# Purpose: Set Docker Socket Permissions after reboot & Docker Logging

###########################
# Docker Socket Permissions
###########################
cat <<EOF > ${HOME}/docker-socket.sh
#!/bin/bash
chmod 666 /var/run/docker.sock
#End
EOF

chmod +x ${HOME}/docker-socket.sh

cat <<EOF > /etc/systemd/system/docker-socket.service
[Unit]
Description=Docker Socket Permissions
After=docker.service
BindsTo=docker.service
ReloadPropagatedFrom=docker.service

[Service]
Type=oneshot
ExecStart=${HOME}/docker-socket.sh
ExecReload=${HOME}/docker-socket.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl restart docker-socket.service

systemctl enable docker-socket.service

JENkINS
# END