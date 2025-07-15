#!/bin/bash

# Build the infra
terraform apply -auto-approve

# Capture the output variables
RESOURCE_GROUP=$(terraform output resource_group_name | tr -d '"')
CLUSTER_NAME=$(terraform output aks_cluster_name | tr -d '"')

# Fetch AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# Install the Retina Helm chart with Hubble Control Plane
VERSION=$( curl -sL https://api.github.com/repos/microsoft/retina/releases/latest | jq -r .name)
helm upgrade --install retina oci://ghcr.io/microsoft/retina/charts/retina-hubble \
        --version $VERSION \
        --namespace kube-system \
        --set os.windows=true \
        --set operator.enabled=true \
        --set operator.repository=ghcr.io/microsoft/retina/retina-operator \
        --set operator.tag=$VERSION \
        --set agent.enabled=true \
        --set agent.repository=ghcr.io/microsoft/retina/retina-agent \
        --set agent.tag=$VERSION \
        --set agent.init.enabled=true \
        --set agent.init.repository=ghcr.io/microsoft/retina/retina-init \
        --set agent.init.tag=$VERSION \
        --set logLevel=info \
        --set hubble.tls.enabled=false \
        --set hubble.relay.tls.server.enabled=false \
        --set hubble.tls.auto.enabled=false \
        --set hubble.tls.auto.method=cronJob \
        --set hubble.tls.auto.certValidityDuration=1 \
        --set hubble.tls.auto.schedule="*/10 * * * *"

# Deploy the test workload and service
kubectl apply -f ./deploy.yaml

# Use retina to start a capture of the network traffic inbound to the service using ExternalTrafficPolicy=Local
retina capture create \
  --name echoserver-trace-local \
  --pod-selectors "app=echoserver" \
  --namespace-selectors "kubernetes.io/metadata.name=default" \
  --duration 10s 

# Curl the service to generate some traffic
ENDPOINT=$(kubectl get service echoserver-local -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
for i in {1..10}; do curl -sk https://$ENDPOINT > /dev/null; done

# Wait for the capture to complete
sleep 10

# Capture the service using ExternalTrafficPolicy=Cluster (for comparison)
retina capture create \
  --name echoserver-trace-cluster \
  --pod-selectors "app=echoserver" \
  --namespace-selectors "kubernetes.io/metadata.name=default" \
  --duration 10s

# Curl the service to generate some traffic
ENDPOINT=$(kubectl get service echoserver-cluster -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
for i in {1..10}; do curl -sk https://$ENDPOINT > /dev/null; done

# Wait for the capture to complete
sleep 10

# Download the captures
retina capture download --name echoserver-trace-local --output ./traces/
retina capture download --name echoserver-trace-cluster --output ./traces/