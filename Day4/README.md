# Day 4

## Lab - Rancher with two clusters

List the clusters from the rancher vm
```
kubectl get clusters.management.cattle.io -o custom-columns="ID:.metadata.name,NAME:.spec.displayName"
```
<img width="480" height="300" alt="image" src="https://github.com/user-attachments/assets/8559ad39-22e3-46ba-8c45-1993a48392e3" />

My Rancher Management GUI looks as below
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/ff4fc67f-c2c7-4ba2-bbe4-bb8d5770b075" />

Let's create a Cluster Group. On your Ranger Webconsole, click on Continuous Delivery
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/c272b3fd-c112-4cd6-abf8-3b021d9d9277" />
Now, let's create a Cluster Group named "tektutor-cluster-group"
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/f92e1a66-201f-41b4-8b34-231b309ef80c" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/e7034ce7-5564-4138-baca-276497768a2c" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/acd82804-6a28-4856-9b95-4c6f05c0fdcf" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/38fb95de-38fb-4474-885e-3c7e71028b08" />

Let's make the cluster1 as dev and cluster2 as prod environment
```
kubectl label clusters.management.cattle.io c-6fvtr env=dev project=tektutor --overwrite
kubectl label clusters.management.cattle.io c-j2759 env=prod project=tektutor --overwrite

# List both cluster along with the labels 
kubectl get clusters.management.cattle.io -L env,project
```
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/deb8067a-f720-40ab-a325-ae0dc977d57f" />
<img width="1911" height="1111" alt="image" src="https://github.com/user-attachments/assets/45901bc3-9548-4fc0-87c9-4d73eb0b6c38" />
