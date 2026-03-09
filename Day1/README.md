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
```
