# Day 1

## Lab - Install Podman in RHEL v9.7
```
sudo su -
dnf update
dnf install -y container-tools
podman version
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/858a8c1c-808c-4347-be9b-08e1445be9b0" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/103ba698-488f-4f00-9714-1b85f431c5e7" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/bcee86c2-c8e4-49a1-96fd-e23a52105c30" />

## Lab - Install KVM Hypervisor in RHEL 9.7
```
sudo su -

# Check if virtualization is supported on your lab machine, if you see vmx/svm it is supported
egrep '(vmx|svm)' /proc/cpuinfo

# Enable RHEL Repositories
subscription-manager repos \
--enable=rhel-9-for-x86_64-baseos-rpms \
--enable=rhel-9-for-x86_64-appstream-rpms

dnf update -y

dnf groupinstall "Virtualization Host" -y

systemctl enable --now libvirtd
systemctl status libvirtd

usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Verify if KVM is installed properly
lsmod | grep kvm
virsh list --all

# Install KVM GUI
dnf install -y virt-manager
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/a3767189-0598-4853-99f0-e7ddc2737956" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/e20d5f26-4ebc-4591-8383-d5c444dc8556" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/328833a6-64f8-4071-8492-3e5d46fbe83c" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/aa9fde0f-903d-41d1-819c-474f03c0389d" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/0c2a7d4c-2c40-4f85-8a5b-af544826ed73" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/28b1db70-6ddd-4175-9447-c8f46120cd8b" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/fff40404-90a4-4df4-aa00-a384b124317d" />


## Info - Kubernetes
<pre>
- it is one of the Container Orchestration Platforms
- it is developed in Golang by Google
- it is opensource and free for personal & commercial use
- any containerized application workloads can be deployed into Kubernetes a.k.a k8s
- it generally as group(cluster) of machines/nodes
- there are 2 types of nodes
  - Master node ( Control Plane components will be running here )
  - Worker node ( user application workloads will be running here )
- Kubernetes Control Plane
  1. API Server
  2. etcd database
  3. Scheduler
  4. Controller Managers ( a group of many Controllers )
- it supports only Command-line interface
- supports extending its Kubernetes API(features) by adding
  - Custom Resources by defining Custom Resource Definitions a.k.a CRD
  - Custom Controller to manage your Custom Resources
  - it is generally installed as Kubernetes Operators
  - Kubernetes Operators
    - a packaged CRs(CRDs) with many custom controllers to manage the CRs
- we can only deploy application for which there is a Container Image
- it is your responsibility to build a custom container image with your custom application + all its dependencies
- the client tool used is kubectl
- with the help kubectl we can interact with Kubernetes cluster
- kubeadm
  - is the administration client tool
  
</pre>  

## Info - Openshift
<pre>
- it is a Container Orchestration Platform
- it is developed by Red Hat on top of opensource Kubernetes
- Red Hat has added many additional features on top of Kubernetes
  - Web Console
  - User Management 
  - Internal Container Registry
  - Many new features
    - S2I - Source to Image i.e one can deploy application from source code coming from Version Control
  - Route
  - Build, BuildConfig, DeploymentConfig
- Openshift is a superset of Kubernetes
- Official definition - OpenShift is Red Hat's Kubernetes Distribution
- all the features that works in k8s will also work in Openshift
- OpenShift support many additional features on top of what is already supported by Kubernetes
- Openshift added additional features on top of K8s using the K8s Operators 
- Openshift Operators
  - one or more Custom Resources defined as CRDs
  - one or more Custom Controllers that manages the custom resources (CRs)
- kubectl and oc i.e client tools can be used be in Openshift to manage your application deployments
- oc Openshift client tool combines kubectl and kubeadm with many additional features 
- Openshift supports one cluster under the hood
- Openshift only supports
  - Openshift cluster 
  - Master Node ( only Red Hat Enterprise Core OS[RHCOS] is supported )
  - Worker Node ( either you can install RHEL or RHCOS ) 
  - v4.x onwards, only supports Podman Container Engine with CRI-O Container Runtime
</pre>  

## Info - Rancher Overview
<pre>
- it orchestrates/manages one or more Kubernetes Cluster  
- it is developed and maintained by SUSE
- there are 2 flavours
  - Rancher Community Edition ( this is opensource and free for personal and commercial use )
  - Rancher Prime ( Licensed - Enterprise Product )
- functionally both the community edition and the Rancher Prime are same
- Rancher Prime
  - comes with world-wide support from SUSE
  - have access to curated/scanned container images
  - have access to private image registry maintained and certified by SUSE
- cluster agnostic
    - it can manager K8s cluster running in EKS(AWS), GKE(Google cloud), AKS(Azure cloud), even on-prem(bare metal) servers
    - it is lighweight
      - it can be installed with Docker container ( Dev/QA/R&D/POC )
    - it is flexible
      - doesn't force a specific workflow
      - youcan bring your own CI/CD, Container Registry, your preferred OS ( Mac OS-X, Windows, Linux )
- container runtime/engine agnostic
  - K3S supports containerd, Docker and CRI-O
  - RKE2 supports containerd by default, doesn't support Docker but unofficially even CRI-O works 
- supports 2 types of Kubernetes cluster
  - K3S ( Kubernetes cluster )
  - RKE2 ( Kubernetes cluster )
  - you could use any managed Kubernetes cluster running in public cloud
  - you could use your already existing Kubernetes cluster in on-prem data-centers 
</pre>

## Lab - Installing RKE2 Cluster with single master and two worker nodes

#### Copy the RHEL 9.7 iso to libvirt image folder
```

scp palmeto@192.168.3.68:/home/palmeto/Downloads/rhel-9.7-x86_64-dvd.iso /home/palmeto/Downloads

cp /home/palmeto/Downloads/rhel-9.7-x86_64-dvd.iso /var/lib/libvirt/images/
ls -l /var/lib/libvirt/images/
```

#### Create a master node Virtual machine with KVM
```
sudo virt-install \
--name rhel9-rke2-master \
--ram 8192 \
--vcpus 4 \
--disk path=/var/lib/libvirt/images/rhel9-rke2-master.qcow2,size=30 \
--os-variant rhel9.7 \
--location /var/lib/libvirt/images/rhel-9.7-x86_64-dvd.iso \
--network network=default \
--graphics vnc
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/b53546e6-712a-4b8f-9c7c-44fa043767eb" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/feb606d8-d03b-485c-983f-57e3d631e09d" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/00409f46-feba-4bce-9b45-a8cc27018edc" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/01cbcaf4-2121-44b3-b37b-0d0f8f49922a" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/7f3bbac1-8b4e-479b-b354-0b719e6b6ec7" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/c241ffba-8d88-4f9f-af98-3bef918c4802" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/1a24b3f3-92dd-440d-b012-beaf42f8f69c" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/2fa09fd3-405f-4a13-892b-692d3be1c254" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/a74c5942-62cc-49ee-8e1b-53bf61fd99cc" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/fc37e506-1026-4456-8ee3-0c5da11c1386" />

Let's login to the master node vm and register the OS with Red Hat
```
hostnamectl set-hostname master.k8s.tektutor.org
hostname

subscription-manager register

subscription-manager status

dnf update
dnf install -y vim net-tools chrony

systemctl enable chronyd
systemctl start chronyd
systemctl status chronyd
```
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/90ce5a95-cbad-4e4a-a413-1fd0316346d7" />
<img width="1332" height="959" alt="image" src="https://github.com/user-attachments/assets/73b4937e-3f64-42aa-883f-7b1a4e89830f" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/d220f084-f7fa-4b89-aae9-6ceb22ce58d1" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/fe6ce109-64fc-49e8-ba6c-9d66bdaeae90" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/1b421297-513a-4c09-b82d-af54bb47a081" />



#### Create the worker1 VM in KVM
```
sudo virt-install \
--name rhel9-rke2-worker1 \
--ram 8192 \
--vcpus 4 \
--disk path=/var/lib/libvirt/images/rhel9-rke2-worker1.qcow2,size=30 \
--os-variant rhel9.7 \
--location /var/lib/libvirt/images/rhel-9.7-x86_64-dvd.iso \
--network network=default \
--graphics vnc
```

In the worker1 VM run the below commands
```
hostnamectl set-hostname worker1.k8s.tektutor.org
hostname

subscription-manager register

subscription-manager status

dnf update
dnf install -y vim net-tools chrony

systemctl enable chronyd
systemctl start chronyd
systemctl status chronyd
```

#### Create the worker2 VM in KVM
```
sudo virt-install \
--name rhel9-rke2-worker2 \
--ram 8192 \
--vcpus 4 \
--disk path=/var/lib/libvirt/images/rhel9-rke2-worker2.qcow2,size=30 \
--os-variant rhel9.7 \
--location /var/lib/libvirt/images/rhel-9.7-x86_64-dvd.iso \
--network network=default \
--graphics vnc
```

In the worker2 VM run the below commands
```
hostnamectl set-hostname worker2.k8s.tektutor.org
hostname

subscription-manager register

subscription-manager status

dnf update
dnf install -y vim net-tools chrony

systemctl enable chronyd
systemctl start chronyd
systemctl status chronyd
```

Find the IP address of master, worker1 and worker2 VMs
```
# In Master VM terminal
ifconfig

# In Worker1 VM terminial
ifconfig

# In Worker2 VM terminal
ifconfig
```

On Cloud Host machine, edit the /etc/hosts and type all your VM IP Addresses as shown below
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/aeabc249-f5c2-4712-b9fa-7e9f52ac792f" />

We need to edit the /etc/hosts file on all the VMs and append their IP at the end of the file as shown below
<pre>
192.168.122.90 master.k8s.tektutor.org
192.168.122.2 worker1.k8s.tektutor.org
192.168.122.160 worker2.k8s.tektutor.org
</pre>


From your host machine, try pinging the IP address of all 3 vms
```
ping master
ping worker1
ping worker2
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/ccad46a0-c2c6-4779-8faf-e7ba207bffa7" />


From your RHEL host machine on the cloud, try doing ssh to master vm ( Terminal tab 1 )
```
ssh root@master
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/e1288546-5981-4de3-9452-0eacc7852fc0" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/2847e10c-6a6a-4280-8d0e-2ca836f187f7" />


From your RHEL host machine on the cloud, try doing ssh to worker1 vm ( Terminal tab 2 )
```
ssh root@worker1
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/d04f8dae-cd1f-4602-a793-f93d18debf10" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/f7d16d57-793e-43b0-8682-5a2268c3bc2e" />


From your RHEL host machine on the cloud, try doing ssh to worker2 vm ( Terminal tab 2 )
```
ssh root@worker2
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/03a1911b-33c0-4413-95f7-804d844afc93" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/e314abbb-5740-476f-9f04-b4913e7909ec" />


#### Setup the master RKE2 node Terminal Tab which is already open
```
systemctl stop firewalld

curl -sfL https://get.rke2.io | sh -

systemctl enable rke2-server.service
systemctl start rke2-server.service
systemctl status rke2-server.service

journalctl -u rke2-server -f

# If everything was successful upto this point, you will have the node-token
cat /var/lib/rancher/rke2/server/node-token
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/a46eae36-2b29-455e-92ff-5ad2a8361bfe" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/9ef44863-57ab-4247-9b00-5a27c546a4a9" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/28c9131b-0151-4c99-bc3e-21b4163fd912" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/011038b0-896d-48e0-8582-d3a56dfa01ab" />

#### Setup the worker1 RKE2 node Terminal Tab which is already open
```
systemctl stop firewalld

curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

systemctl enable rke2-agent.service

mkdir -p /etc/rancher/rke2/
touch /etc/rancher/rke2/config.yaml
```

Paste the below in the file /etc/rancher/rke2/config.yaml
<pre>
server: https://master.k8s.tektutor.org:9345
token : paste-your-node-token-from-server-vm 
</pre>

Now your /etc/rancher/rke2/config.yaml should look as shown below
```
cat /etc/rancher/rke2/config.yaml

systemctl start rke2-agent.service
journalctl -u rke2-agent -f
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/67de959d-940c-4d1f-a4da-aa4e8dd167db" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/c29cdf19-7185-4fad-b117-a66e89839295" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/59244d05-c12d-47be-97d4-b35fbfe136b1" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/a1e3222c-476c-4510-ab14-641822198f77" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/8eacc961-25d1-4dfb-8113-6e9b24048fee" />

#### Setup the worker2 RKE2 node Terminal Tab which is already open
```
systemctl stop firewalld

curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

systemctl enable rke2-agent.service

mkdir -p /etc/rancher/rke2/
touch /etc/rancher/rke2/config.yaml
```

Paste the below in the file /etc/rancher/rke2/config.yaml
<pre>
server: https://master.k8s.tektutor.org:9345
token : paste-your-node-token-from-server-vm 
</pre>

Now your /etc/rancher/rke2/config.yaml should look as shown below
```
cat /etc/rancher/rke2/config.yaml

systemctl start rke2-agent.service
journalctl -u rke2-agent -f
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/36c79f77-5b99-41bc-bd69-ca8c1ded91e8" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/eff8d63a-b644-448a-8c87-01d289389801" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/e5bbc20b-1dbb-494b-a6bf-b1c3a2fd7626" />

In the master vm, let's install kubectl client tool
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/bin
kubectl version

```
