# Knime
knime preparation


# Cluster install - minimal version

```yml
apiVersion: "cluster.kurl.sh/v1beta1"
kind: "Installer"
metadata: 
  name: "35a3844"
spec: 
  kubernetes: 
    version: "1.32.x"
  flannel: 
    version: "0.26.x"
  containerd: 
    version: "1.7.x"

```
```bash
sudo apt install containerd conntrack -y

curl https://kurl.sh/35a3844 | sudo bash
```

# Deploy Storage Class by executing scripts

* Local
```bash
./deploy-local-storageClass.sh
```

* NFS
```bash
./deploy-storageClass.sh
```

# Install Prometheus operator using helm or simply run `./deploy-monitoringStack.sh` script

```bash
cd monitoringStack

helm dependency build

helm upgrade --install prometheus-stack . \
    -n monitoring --create-namespace \
     -f values.yml
```

# Install KNIME-HUB
```bash
curl https://kots.io/install/1.124.17 | sudo bash
kubectl kots install knime-hub
```
