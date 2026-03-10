<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/2787e08e-3fc6-4050-96f6-066996f0e909" /># Day 2

## Lab - Let's automate RKE2 cluster setup using Rancher

This is our plan
<pre>
- Let's create a golden image to create thin-clone with KVM, this will reduce the actual disk usage.
- We will have to install RHEL v9.7 manually on the golden image, later we will clone this image to setup other VMs
- We will setup a single node RKE2 to setup Rancher
- Using Terraform, let's provision VMs using KVM
- Let's automate the RKE2 cluster setup using Rancher
</pre>

Create a golden RHEL image with qcow2
```
qemu-img create -f qcow2 /var/lib/libvirt/images/rhel9-golden.qcow2 40G
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/2f112c28-6a73-4b91-b5d3-e04e1c8e6566" />


Install RHEL v9.7 using the RHEL DVD iso
```
sudo virt-install \
--name rhel9-golden \
--ram 4096 \
--vcpus 2 \
--disk path=/var/lib/libvirt/images/rhel9-golden.qcow2,size=40 \
--os-variant rhel9.7 \
--location /var/lib/libvirt/images/rhel-9.7-x86_64-dvd.iso \
--network network=default \
--graphics vnc
```

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/29689833-9508-46a1-b169-2bbda239a939" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/399a2f6d-06c1-4a28-a6ef-998a5e95935e" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/4f81d477-a3fd-4618-a33e-8069d307f0b9" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/751d5a00-aafc-4a3d-b256-d175ed72c3e2" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/77a0f38e-bbf0-4f27-9c3e-020257f5e838" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/62ba6f41-e87a-4f87-b038-1f587dfb483b" />

Let's install the below tools in the golden vm
```
sudo dnf update -y

sudo dnf install -y \
 net-tools \
 chrony  \
 curl \
 wget \
 vim \
 tar \
 git \
 qemu-guest-agent \
 nfs-utils \
 iproute \
 conntrack-tools \
 socat
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/7269c6a1-1bd6-4a47-9d06-845b95a21bdc" />

Enable guest agent
```
sudo systemctl enable qemu-guest-agent
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/17540fcd-08b0-4407-a5a2-9960012db8b5" />

Disable swap
```
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

Configure Kernel modules
```
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

Load modules
```
sudo modprobe overlay
sudo modprobe br_netfilter
```

Configure networking parameters
```
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

Disable firewall
```
sudo systemctl disable firewalld
sudo systemctl stop firewalld
```

Allow password-less sudo for automation
```
sudo visudo

# Add/Uncomment save and quit the file
%wheel ALL=(ALL) NOPASSWD: ALL
```

Clean the image before cloning
```
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo dnf clean all
sudo rm -rf /var/log/*
```

Shutdown the VM
```
sudo shutdown now
```

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/552b421c-4c63-4118-adc9-8851eb708135" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/11c74ee6-50be-4c7c-8f5b-61760833152e" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/9d6632ec-e8e2-42eb-8fe7-04def000717a" />

Mark golden image as template
```
mkdir -p ~/kvm-images/templates
mv /var/lib/libvirt/images/rhel9-golden.qcow2 ~/kvm-images/templates/
chmod 444 ~/kvm-images/templates/rhel9-golden.qcow2
```

Create linked clone disks
```

mv ~/kvm-images/templates/rhel9-golden.qcow2 /var/lib/libvirt/images/

qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b /var/lib/libvirt/images/rhel9-golden.qcow2 \
  /var/lib/libvirt/images/master01.qcow2

qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b /var/lib/libvirt/images/rhel9-golden.qcow2 \
  /var/lib/libvirt/images/worker01.qcow2

qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b /var/lib/libvirt/images/rhel9-golden.qcow2 \
  /var/lib/libvirt/images/worker02.qcow2

ls -l /var/lib/libvirt/images/
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/98eaf921-d0bf-4476-8841-65ad5182ce59" />

Boot the Master VM
```
virt-install \
 --name master01 \
 --ram 8192 \
 --vcpus 4 \
 --disk path=/var/lib/libvirt/images/master01.qcow2 \
 --import \
 --os-variant rhel9.7 \
 --network network=default \
 --graphics none

virsh domifaddr master01
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/a41bd602-94fb-4c5f-be86-da19e451a01b" />


Boot the Worker1 VM
```
virt-install \
 --name worker01 \
 --ram 8192 \
 --vcpus 4 \
 --disk path=/var/lib/libvirt/images/worker01.qcow2 \
 --import \
 --os-variant rhel9.7 \
 --network network=default \
 --graphics none

virsh domifaddr worker01
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/e1b0d6d4-e72a-4ee7-bde5-3cbc7263ed86" />


Boot the Worker2 VM
```
virt-install \
 --name worker02 \
 --ram 8192 \
 --vcpus 4 \
 --disk path=/var/lib/libvirt/images/worker02.qcow2 \
 --import \
 --os-variant rhel9.7 \
 --network network=default \
 --graphics none

virsh domifaddr worker02
```

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/5a930f36-93a8-4152-befb-3f6a5cf67130" />


In your Host machine, add the IP address of your master and worker nodes
```
cat /etc/hosts
```

From Host machine Terminal Tab 1
```
ssh root@master
hostnamectl set-hostname master.k8s.tektutor.org

hostname
```

From Host machine Terminal Tab 1
```
ssh root@master
hostnamectl set-hostname worker1.k8s.tektutor.org

hostname
```


From Host machine Terminal Tab 1
```
ssh root@master
hostnamectl set-hostname worker2.k8s.tektutor.org

hostname
```

Let's create a single node RKE2 cluser to deploy rancher
```
qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b /var/lib/libvirt/images/rhel9-golden.qcow2 \
  /var/lib/libvirt/images/rancher.qcow2

virt-install \
 --name rancher \
 --ram 8192 \
 --vcpus 4 \
 --disk path=/var/lib/libvirt/images/rancher.qcow2 \
 --import \
 --os-variant rhel9.7 \
 --network network=default \
 --graphics none

virsh domifaddr rancher

ssh root@192.168.122.131

systemctl stop firewalld

curl -sfL https://get.rke2.io | sh -

systemctl enable rke2-server.service
systemctl start rke2-server.service
systemctl status rke2-server.service


curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/bin
kubectl version

mkdir -p /root/.kube
cp /etc/rancher/rke2/rke2.yaml /root/.kube/config
kubectl get nodes
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/7c6895b3-8d2d-4820-ae8a-5b8b4b0e76dc" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/c9206dac-ba9c-4b31-bd80-a4d15cbfd0a9" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/6cdb82dd-3d2e-4134-ad7c-2d631442bd65" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/3fa2136c-92c3-4172-a1f1-63b5a177c0ca" />

## Let's install Rancher from the Master node 
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml
kubectl get crds | grep cert-manager

# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.14.5
  --set installCRDs=false

kubectl get pods -n cert-manager

kubectl create namespace cattle-system

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.k8s.tektutor.org \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=secret

kubectl get pods -n cattle-system
kubectl get ingress -n cattle-system
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/806159f3-ffae-4603-83cd-49a5ce46dc99" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/9297fe50-44c3-4624-aea4-9d29b68b3346" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/ebc9a19f-4c3b-4388-93a1-c2dab94db541" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/648a75a8-c0ea-458d-bed6-72daebe82794" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/64c84215-5a4a-4051-bf14-8c2851bca21e" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/bd7ab1a8-2455-4fee-9b63-2676caf4b729" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/82dce73d-9595-4c18-915c-b88bd02aa5e5" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/9cbb5bfd-1425-42bd-9be2-d6a64ddc4f98" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/644d93a5-94ed-4812-93a1-597268f4b293" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/ceeae279-5cec-4f35-a053-d09f5a33beed" />
<img width="1911" height="1124" alt="image" src="https://github.com/user-attachments/assets/2e9aa8df-5f90-49fc-94a9-07db32bf6cb3" />
<img width="1911" height="1124" alt="image" src="https://github.com/user-attachments/assets/f7607626-11f0-485d-8a3c-db13db21f876" />
<img width="1911" height="1124" alt="image" src="https://github.com/user-attachments/assets/dc01dffa-b9eb-45e9-9531-f376fd0c5647" />

Accessing your Rancher Webconsole
<pre>
https://rancher.k8s.tektutor.org  
</pre>

<img width="1911" height="1124" alt="image" src="https://github.com/user-attachments/assets/46aa8dcc-2192-4aa1-bb49-c1070fd4de80" />
<img width="1911" height="1124" alt="image" src="https://github.com/user-attachments/assets/7586ef7c-f58b-4305-abe0-fadc634289da" />

Let's automate the RKE2 Cluster using Rancher
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/317f7b4a-c86d-40c2-9d8c-1347402ff5db" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/1c3a5eea-2799-4eef-8a2a-d9905362c60c" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/c88dceeb-031b-425f-a30f-fbf078983457" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/408450ed-0fd1-4d4a-ac8f-75db2e303b95" />

On the master node VM terminal
```
curl -k https://rancher.k8s.tektutor.org/v3/settings/cacerts | jq -r .value | sha256sum

curl --insecure -fL https://rancher.k8s.tektutor.org/system-agent-install.sh | sudo sh -s - --server https://rancher.k8s.tektutor.org --label 'cattle.io/os=linux' --token gcp8dz46hxzl55qwgxwmh7bckfn7p5wfz6m8zvbmthzcqvtzg55ntl --etcd --controlplane --worker --address 192.168.122.73 --internal-address 192.168.122.73 --node-name master.k8s.tektutor.org --ca-checksum 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b


```


Update your worker1 details in Rancher webconsole
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/6d6f5cc1-5634-4a2c-9241-420133c3dbb6" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/f7a3492c-97fe-483c-87d0-1e12bf3b7a17" />

Run this command on your worker1 vm terminal
```
curl -k https://rancher.k8s.tektutor.org/v3/settings/cacerts | jq -r .value | sha256sum

curl --insecure -fL https://rancher.k8s.tektutor.org/system-agent-install.sh | sudo sh -s - --server https://rancher.k8s.tektutor.org --label 'cattle.io/os=linux' --token gcp8dz46hxzl55qwgxwmh7bckfn7p5wfz6m8zvbmthzcqvtzg55ntl --worker --address 192.168.122.26 --internal-address 192.168.122.26 --node-name worker1.k8s.tektutor.org --ca-checksum 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b

```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/35a31f20-40dc-463b-86b7-cd070bb2e76e" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/3af255d9-97d8-4bc0-b483-77f460e62349" />

Run this command on your worker2 vm terminal
```
curl -k https://rancher.k8s.tektutor.org/v3/settings/cacerts | jq -r .value | sha256sum

curl --insecure -fL https://rancher.k8s.tektutor.org/system-agent-install.sh | sudo sh -s - --server https://rancher.k8s.tektutor.org --label 'cattle.io/os=linux' --token gcp8dz46hxzl55qwgxwmh7bckfn7p5wfz6m8zvbmthzcqvtzg55ntl --worker --address 192.168.122.34 --internal-address 192.168.122.34 --node-name worker2.k8s.tektutor.org --ca-checksum 01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/6128dad7-6e9e-41df-995b-d43fee72e401" />

