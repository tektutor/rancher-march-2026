# Day 5

## Info - Setup a rancher cluster with Cilium and Traefic Ingress Controller

Note
<pre>
- By default, RKE2 ships with Canal (Calico + Flannel) and Traefik
- In our cluster setup, we will be using Cilium in the place of Canal
</pre>

Create a lightweight VM using podman
```
podman machine init rancher --cpus 4 --memory 8192 --disk-size 50
podman machine start rancher
podman machine ssh rancher
sudo hostnamectl set-hostname rancher.tektutor.org
```

Download the RKE2 binaries inside the rancher VM
```
curl -sfL https://get.rke2.io | sudo sh -
```

Create configuration directories
```
sudo mkdir -p /etc/rancher/rke2/
sudo mkdir -p /var/lib/rancher/rke2/server/manifests/
```

Define Cluster Configurations
```
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
cni: cilium
write-kubeconfig-mode: "0644"
EOF
```

Enable Hubble
```
cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-cilium
  namespace: kube-system
spec:
  valuesContent: |-
    hubble:
      enabled: true
      ui:
        enabled: true
      relay:
        enabled: true
EOF
```

Start the RKE2 Cluster
```
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
```

Verify your Upstream RKE2 Cluster
```
# Set up your environment paths
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=$PATH:/var/lib/rancher/rke2/bin

# Watch the pods come online
watch kubectl get pods -A
```
