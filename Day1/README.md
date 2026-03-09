<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/917066dd-eb05-45aa-a55d-f94d34ef8dd8" /># Day 1

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
