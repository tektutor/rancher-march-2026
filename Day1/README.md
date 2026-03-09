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
# Check if virtualization is supported on your lab machine
egrep -c '(vmx|svm)' /proc/cpuinfo
```
