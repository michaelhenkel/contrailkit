#!/bin/sh
# SUMMARY: Test build and insertion of kernel modules
# LABELS:
# REPEAT:


# Source libraries. Uncomment if needed/defined
#. "${RT_LIB}"
#. "${RT_PROJECT_ROOT}/_lib/lib.sh"

NAME=vrouter
IMAGE_NAME=vrouter

clean_up() {
	docker rmi ${IMAGE_NAME} || true
	rm -rf ${NAME}-*
}
#trap clean_up EXIT

# Make sure we have the latest kernel image
#docker pull linuxkit/kernel:4.19.99
# Build a package
#docker build -t ${IMAGE_NAME} df

# Build and run a LinuxKit image with kernel module (and test script)
echo "Building..."
linuxkit build -format kernel+initrd -name "${NAME}" ymls/contrail.yml > /dev/null 2>&1 
#linuxkit run hyperkit -ip 192.168.65.100 -mem 6000 -cpus 4 -networking vpnkit -publish 6443:6443/tcp -publish 2222:22/tcp -disk file=disk2.img,size=6G,format=qcow2 ${NAME} 
echo "Running..."
linuxkit run hyperkit -mem 10000 -cpus 4 -networking vmnet -console-file -vsock-ports 2374 -disk file=disk2.img,size=6G,format=qcow2 ${NAME} > /dev/null 2>&1 & 
#linuxkit run hyperkit -ip 192.168.64.80 -mem 4096 -cpus 4 -networking vmnet -disk path,size=6G,format=qcow2 ${NAME} 
#RESULT="$(linuxkit run ${NAME})"
#echo "${RESULT}"
echo "Waiting..."
sleep 3
echo "Getting IP..."
ip=$(cat vrouter-state/console-ring |grep "eth0: leased"|awk '{print $3}')
while [[ $ip == "" ]]
do
  ip=$(cat vrouter-state/console-ring |grep "eth0: leased"|awk '{print $3}')
done
echo "Got IP ${ip}"
until nc -zv -G 2 ${ip} 22 > /dev/null 2>&1
do
  echo "Waiting for ssh"
  sleep 2
done
ssh -o LogLevel=FATAL -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes root@${ip} 'sed -i "s/127.0.0.1.*/127.0.0.1 $(hostname)/g" /etc/hosts'
until nc -zv -G 2 ${ip} 6443 > /dev/null 2>&1
do
  echo "Waiting for k3s"
  sleep 2
done
echo "Getting k3s config..."
ssh -o LogLevel=FATAL -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes root@${ip} 'ctr --namespace services.linuxkit tasks exec --exec-id ssh-xx k3s /bin/cat /etc/rancher/k3s/k3s.yaml' > /dev/null 2>&1
while [[ $? -ne 0 ]]
do
  ssh -o LogLevel=FATAL -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes root@${ip} 'ctr --namespace services.linuxkit tasks exec --exec-id ssh-xx k3s /bin/cat /etc/rancher/k3s/k3s.yaml'  > /dev/null 2>&1
done
ssh -o LogLevel=FATAL -o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes root@${ip} 'ctr --namespace services.linuxkit tasks exec --exec-id ssh-xx k3s /bin/cat /etc/rancher/k3s/k3s.yaml' > ~/k3config.yaml
echo "Got k3s config..."
sed -i '' "s/127.0.0.1/${ip}/g" ~/k3config.yaml
echo "Done..."
echo "export KUBECONFIG=~/k3config.yaml"
echo "https://${ip}:8143"

exit 0
