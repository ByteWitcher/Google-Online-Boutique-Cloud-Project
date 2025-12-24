#!/bin/bash

# Install kube-prometheus-stack using Helm on a new dedicated namespace 'monitoring'
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --set prometheusOperator.admissionWebhooks.enabled=false --set prometheusOperator.tls.enabled=false

# Get the Grafana admin password
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo 

echo "Waiting for all pods to be ready..."
while true; do
    NOT_READY=$(kubectl get pods -n monitoring --no-headers | awk '{split($2,a,"/"); if(a[1]!=a[2]) print $0}' | wc -l)
    if [[ "$NOT_READY" -eq 0 ]]; then
        break
    fi
    echo -n "."
    sleep 5
done
echo "All pods are ready!"

# Port-forward Grafana service to access it locally
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 8080:80