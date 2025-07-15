# ExternalTrafficPolicy and ClientIP forwarding in AKS
This repo is a playground for testing layer 4 behavior at the Azure LB when running k8s services with externalTrafficPolicy=Local

To get started clone this repo and run ```runme.sh``` which will:
1. Create an AKS cluster via terraform configured to use Azure CNI overlay powered by Cilium as the network stack
1. Install [retina](https://retina.sh/docs/Introduction/intro) with the [Hubble](https://github.com/cilium/hubble) controlplane on the cluster
1. Deploy a dummy workload that spreads three replicas across the available nodes
1. Deploy two ```LoadBalancer``` type services
    1. One configured with ```externalTrafficPolicy: Local```
    1. One configured with ```externalTrafficPolicy: Cluster``` (default service behavior)
1. Run a packet capture for both services
1. Download the [results](https://retina.sh/docs/Captures/cli#file-and-directory-structure-inside-the-tarball) to ```./traces/```