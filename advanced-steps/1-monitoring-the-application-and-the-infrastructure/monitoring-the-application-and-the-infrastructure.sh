#!/bin/bash

# Install kube-prometheus-stack using Helm on a new dedicated namespace 'monitoring'
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set prometheusOperator.admissionWebhooks.enabled=false --set prometheusOperator.tls.enabled=false

# Get the Grafana admin password
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo 

# WAIT for all pods to be in Running state
sleep 30

# Port-forward Grafana service to access it locally
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 8080:80