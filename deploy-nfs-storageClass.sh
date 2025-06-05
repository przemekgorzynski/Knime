#!/bin/bash

helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

helm repo update

cd nfs-storageClass

helm dependency build

helm upgrade --install nfs-csi . \
  -n kube-system --create-namespace \
  -f values.yml