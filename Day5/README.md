# Day 5

## Lab - Setup Rancher Upstream cluster with Cillium and Traefik Ingress Controller

#### Note
<pre>
- Inspite of my laptop has got 24 CPU Cores, 64 GB RAM and 1 TB SSD I was facing disk full issues
- Root cause - KVM uses /var/lib/libvirt/images to store all KVM VM disk images
- My /var parition is just 70GB, hence when I create just 3~4 VMs it reports no space left.
- My /home parition has 850GB
- Hence, I had configured my KVM to use /home/kvm-images as the KVM shared pool to workaround the issue.
- The reason I'm explain this to you :) is you shall continue using /var/lib/libvirt/images folder
</pre>

#### Let's create 3 Disk images
```
sudo qemu-img create -f qcow2 -b /home/kvm-images/ubuntu-base.img -F qcow2 /home/kvm-images/rancher-server.qcow2 50G
sudo qemu-img create -f qcow2 -b /home/kvm-images/ubuntu-base.img -F qcow2 /home/kvm-images/cluster1-node.qcow2  50G
sudo qemu-img create -f qcow2 -b /home/kvm-images/ubuntu-base.img -F qcow2 /home/kvm-images/cluster2-node.qcow2  50G
```

#### Let's create the cloud-init file in current directory
```
cat <<EOF > cloud-init.yaml
#cloud-config
user: root
password: root
chpasswd: { expire: False }
ssh_pwauth: True
runcmd:
  - sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
EOF
```

#### Let's create the rancher vm
```
sudo virt-install \
  --name rancher-server \
  --memory 8192 \
  --vcpus 4 \
  --disk /home/kvm-images/rancher-server.qcow2 \
  --import \
  --os-variant ubuntu24.04 \
  --network bridge=virbr0 \
  --graphics none \
  --noautoconsole \
  --cloud-init user-data=./cloud-init.yaml
```

#### Let's create the cluster1 vm
```
sudo virt-install \
  --name cluster1 \
  --memory 8192 \
  --vcpus 4 \
  --disk /home/kvm-images/cluster1-node.qcow2 \
  --import \
  --os-variant ubuntu24.04 \
  --network bridge=virbr0 \
  --graphics none \
  --noautoconsole \
  --cloud-init user-data=./cloud-init.yaml
```

#### Let's create the cluster2 vm
```
sudo virt-install \
  --name cluster2 \
  --memory 8192 \
  --vcpus 4 \
  --disk /home/kvm-images/cluster2-node.qcow2 \
  --import \
  --os-variant ubuntu24.04 \
  --network bridge=virbr0 \
  --graphics none \
  --noautoconsole \
  --cloud-init user-data=./cloud-init.yaml
```

#### List all the KVM virtual machines
```
sudo virsh list --all
```

#### In the host machine /etc/hosts
```
192.168.122.247 rancher
192.168.122.156 cluster1
192.168.122.123 cluster2

192.168.122.247 rancher.tektutor.org
192.168.122.156 cluster1.tektutor.org
192.168.122.123 cluster2.tektutor.org
```

#### In all the 3 VMS, append the below entries at the end of /etc/hosts file
```
192.168.122.247 rancher.tektutor.org
192.168.122.156 cluster1.tektutor.org
192.168.122.123 cluster2.tektutor.org
```

### In the rancher VM
```
ssh root@rancher

sudo mkdir -p /etc/rancher/rke2/
sudo mkdir -p /var/lib/rancher/rke2/server/manifests/
```

#### Define Cluster configurations
```
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
cni: cilium
write-kubeconfig-mode: "0644"
disable:
  - rke2-ingress-nginx
EOF
```

#### Enable Traefic - Create this file /var/lib/rancher/rke2/server/manifests/traefik-install.yaml
```
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  chart: traefik
  repo: https://traefik.github.io/charts
  targetNamespace: kube-system
  valuesContent: |
    ingressClass:
      enabled: true
      isDefaultClass: true
    service:
      type: LoadBalancer
```

#### Enable Hubble
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

#### Download RKE2 binaries
```
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_METHOD="tar" sh -
```

#### Start the RKE2 Cluster
```
sudo systemctl daemon-reload
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
sudo systemctl status rke2-server.service
sudo rke2 server status
```

#### Test the cluster
```
mkdir ~/.kube
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config
sudo ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
kubectl get pods -A
```

## Let's install Rancher from the Master node 
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml
kubectl get crds | grep cert-manager
```

#### Install helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.14.5 \
  --set installCRDs=false

kubectl get pods -n cert-manager

kubectl create namespace cattle-system

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.tektutor.org \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=secret

kubectl get pods -n cattle-system
kubectl get ingress -n cattle-system
```

#### Accessing your Rancher Webconsole
<pre>
https://rancher.tektutor.org  
</pre>

#### Generate a private key
```
sudo mkdir -p /etc/rancher/ssl
sudo openssl genrsa -out /etc/rancher/ssl/rancher.key 4096
```

#### Generate the self-signed certificate
```
sudo tee /etc/rancher/ssl/rancher-openssl.cnf > /dev/null <<EOF
[ req ]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = IN
ST = TN
L  = Hosur
O  = TekTutor
OU = IT
CN = rancher.tektutor.org

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = rancher.tektutor.org
EOF
```

#### Generate self-signed certificate
```
sudo openssl req -x509 -nodes -days 365 \
 -key /etc/rancher/ssl/rancher.key \
 -out /etc/rancher/ssl/rancher.crt \
 -config /etc/rancher/ssl/rancher-openssl.cnf \
 -extensions req_ext

# Verify the certificate
openssl x509 -text -noout -in /etc/rancher/ssl/rancher.crt
```

#### Replace self-signed certificate in rancher cluster
```
ls -l /etc/rancher/ssl/
sudo cp /etc/rancher/ssl/rancher.crt /etc/rancher/ssl/tls.crt
sudo cp /etc/rancher/ssl/rancher.key /etc/rancher/ssl/tls.key

sudo mkdir -p /etc/rancher/rke2/ssl
sudo cp /etc/rancher/ssl/rancher.crt /etc/rancher/rke2/ssl/tls.crt
sudo cp /etc/rancher/ssl/rancher.key /etc/rancher/rke2/ssl/tls.key
sudo chown root:root /etc/rancher/rke2/ssl/tls.*
sudo chmod 600 /etc/rancher/rke2/ssl/tls.key

kubectl -n cattle-system rollout restart deployment rancher
sudo kubectl -n cattle-system create secret tls tls-rancher \
  --cert=/etc/rancher/rke2/ssl/tls.crt \
  --key=/etc/rancher/rke2/ssl/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n cattle-system patch ingress rancher \
  --type='merge' \
  -p '{"spec":{"tls":[{"hosts":["rancher.tektutor.org"],"secretName":"tls-rancher"}]}}'

kubectl -n cattle-system rollout restart deployment rancher

openssl s_client -connect rancher.tektutor.org:443 -servername rancher.tektutor.org </dev/null | openssl x509 -noout -subject -issuer -
```

## Setup Downstream Cluster1

Ensure these kernel modules are loaded
```
sudo modprobe overlay
sudo modprobe br_netfilter
```

Cilium needs to be able to see bridged traffic
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

### In the rancher VM
```
ssh root@rancher

sudo mkdir -p /etc/rancher/rke2/
sudo mkdir -p /var/lib/rancher/rke2/server/manifests/
```

#### Define Cluster configurations
```
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
cni: cilium
write-kubeconfig-mode: "0644"
disable:
  - rke2-ingress-nginx
EOF
```

#### Enable Traefik - Create this file /var/lib/rancher/rke2/server/manifests/traefik-install.yaml
```
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  chart: traefik
  repo: https://traefik.github.io/charts
  targetNamespace: kube-system
  valuesContent: |
    ingressClass:
      enabled: true
      isDefaultClass: true
    service:
      type: LoadBalancer
```

#### Download RKE2 binaries
```
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_METHOD="tar" sh -
```

#### Start the RKE2 Cluster
```
sudo systemctl daemon-reload
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
sudo systemctl status rke2-server.service
sudo rke2 server status
```

#### Test the cluster
```
mkdir ~/.kube
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config
sudo ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
kubectl get pods -A
```

#### Troubleshooting - Checking if a particular cluster is connecting
```
kubectl get clusters.management.cattle.io c-wbqcg -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | jq
```

#### Finally, you should see this
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/d1392cd0-99fa-4ff1-a0fa-6185b650cad9" />

## Lab - Fleet GitOps CI/CD

<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/e3f9d30f-a80f-4379-b705-bdc6e3d18285" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/8655d1c6-5878-47cb-8c06-4b4b50169166" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/8db5f006-da1c-456a-915d-e6694793e3e6" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/a3564145-7218-42e1-b1cb-27bb25caebf8" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/ba14e05d-a1a6-4fd3-ad48-e6c7d4adfb4e" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/0130fe27-566f-4fdf-b58b-8af21b744d32" />

## Lab - Rancher API Automation using curl utility

Get the full list of Rancher API supports
<pre>
curl -k -H "Authorization: Bearer  token-6lt5v:6pkwbcgtbtwrhn4v56nmvkfnxfb4wn4rjznrx8mc962d78tszjgmgs" https://rancher.tektutor.org/v3/schemas | jq
</pre>


Get the list of projects
<pre>
curl -k -H "Authorization: Bearer  token-6lt5v:6pkwbcgtbtwrhn4v56nmvkfnxfb4wn4rjznrx8mc962d78tszjgmgs" https://rancher.tektutor.org/v3/projects | jq  
</pre>

<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/27ca0d9f-68b6-4331-a5af-26b9925dea56" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/b063baa6-3be6-4ea2-91c5-8ea240ec2ed5" />


### Lab - Get list of projects using python

Create a python script getprojects.py
<pre>
import requests
import json
import urllib3

RANCHER_URL = "https://rancher.tektutor.org"
TOKEN = "token-6lt5v:6pkwbcgtbtwrhn4v56nmvkfnxfb4wn4rjznrx8mc962d78tszjgmgs"

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type" : "application/json"
}

def getRancherProjects():

    clusterId = "c-zlts7"
    url = f"{RANCHER_URL}/v3/Projects"

    try:

        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        session = requests.Session()
        session.verify = False

        response = requests.get(url, headers=HEADERS, verify=True)
        response.raise_for_status()

        data = response.json()
        projects = data.get('data', [])

        print(f"{'PROJECT NAME':<30} | {'PROJECT ID':<15} | {'CLUSTER ID':<15}")
        print("-" * 65 )

        for project in projects:
            name = project.get('name')
            p_id = project.get('id')
            c_id = project.get('clusterId')
            print(f"{name:<30} | {p_id:<15} | {c_id:<15}")

    except requests.exceptions.HTTPError as err:
        print(f"HTTP Error: {err}")
    except Exception as e:
        print(f"An error occured: {e}")

getRancherProjects()  
</pre>

Run it
```
python3 getprojects.py
```
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/bfc4132a-a05f-44e3-b3d2-8c4a6ba6d42a" />

## Lab - Create a project using Rancher API in Python

Create a createproject.py with below code
<pre>
import requests
import urllib3
import json

# 1. Suppress SSL warnings for self-signed certs
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- CONFIGURATION ---
RANCHER_URL = "https://rancher.tektutor.org"
API_TOKEN = "token-6lt5v:6pkwbcgtbtwrhn4v56nmvkfnxfb4wn4rjznrx8mc962d78tszjgmgs"  # Your full Bearer Token
NEW_PROJECT_NAME = "MyProject"
# ---------------------

def create_upstream_project(project_name):
    # Endpoint for project creation
    url = f"{RANCHER_URL}/v3/projects"
    
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }

    # The payload requires the clusterId to match the upstream cluster ('local')
    payload = {
        "name": project_name,
        "clusterId": "local",
        "description": "Created via Python API script"
    }

    try:
        response = requests.post(
            url, 
            headers=headers, 
            json=payload, 
            verify=False
        )
        
        # Check for success (201 Created)
        response.raise_for_status()
        
        result = response.json()
        print(f"Success! Project Created.")
        print(f"Project Name: {result.get('name')}")
        print(f"Project ID:   {result.get('id')}")

    except requests.exceptions.HTTPError as err:
        print(f"Failed to create project.")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    create_upstream_project(NEW_PROJECT_NAME)  
</pre>

Run it
```
python3 ./createproject.py
```
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/06e09117-2de2-4b6a-879e-dc29da58a756" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/cde1aed6-a727-41f2-a685-de6e956583bc" />
