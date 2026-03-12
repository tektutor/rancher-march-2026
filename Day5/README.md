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
hostname
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/38d19e7a-57c4-400a-a9f0-cbcf80e6a4bb" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/06f15de2-6090-4eb3-a4d1-6a50021ea6c0" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/49b98704-0cc1-4690-b0d9-6f82fbde6e4d" />


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

Download RKE2 binaries
```
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_METHOD="tar" sh -
```

Start the RKE2 Cluster
```
sudo systemctl daemon-reload
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
sudo systemctl status rke2-server.service
sudo rke2 server status
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/b2a77898-8bb6-4d64-8285-c99ba446d5a7" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/4e18cd88-ae73-4fdd-99de-a8e17ad16c11" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/daac684a-afaf-4b49-a2b3-496de60559cc" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/7d3d1764-ff40-49a3-8480-451195f19fc9" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/7d6e138b-eb9b-49be-8f39-3aa5cd4f242f" />

Test the cluster
```
mkdir ~/.kube
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config
sudo ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
kubectl get pods -A
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/f7ec8048-5c19-440f-be37-5707dca37d2f" />

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

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/fe35a603-6cb8-4042-8082-fd7e66804bbc" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/f1e19583-2456-45aa-84c3-548a742d000e" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/6611c28a-bdee-4f96-81b6-2deee56dd49f" />

Make sure the rancher vm IP is added to your host machine /etc/hosts before accessing the Rancher Webconsole
```
echo "192.168.127.2 rancher.tektutor.org" >> /etc/hosts
cat /etc/hosts
```

Accessing your Rancher Webconsole
<pre>
https://rancher.tektutor.org  
</pre>

Generate a private key
```
sudo mkdir -p /etc/rancher/ssl
sudo openssl genrsa -out /etc/rancher/ssl/rancher.key 4096
```

Generate the self-signed certificate
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

Generate self-signed certificate
```
sudo openssl req -x509 -nodes -days 365 \
 -key /etc/rancher/ssl/rancher.key \
 -out /etc/rancher/ssl/rancher.crt \
 -config /etc/rancher/ssl/rancher-openssl.cnf \
 -extensions req_ext

# Verify the certificate
openssl x509 -text -noout -in /etc/rancher/ssl/rancher.crt
```

Replace self-signed certificate in rancher cluster
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

openssl s_client -connect rancher.tektutor.org:443 -servername rancher.tektutor.org </dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName

sudo systemctl restart rke2-server
```

In order to access the rancher webconsole from hostname open a tunnel (Do not close this terminal until you are done with rancher)
```
ssh -i ~/.local/share/containers/podman/machine/machine -p 34131 -N -L 8443:localhost:443 core@127.0.0.1
```

Now you may access the rancher webconsole from host machine browser
```
https://rancher.tektutor.org:8443
```
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/962d2f7d-2da5-4193-a380-215d02533e88" />

