#!/bin/bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

cd monitoringStack

helm dependency build

helm upgrade --install prometheus-stack . \
    -n monitoring --create-namespace \
     -f values.yml