# NATS Gateway Configuration Examples

This directory contains example configurations for setting up NATS superclusters using gateway connectivity.

## Overview

NATS gateways allow you to connect multiple NATS clusters across different Kubernetes clusters, regions, or cloud providers to form a unified supercluster. Messages published in any cluster become available across all connected clusters.

## Examples

### Single Gateway Connection

**Scenario**: Connect two clusters (main and remote)

- [cluster-main.yaml](./cluster-main.yaml) - Main cluster configuration
- [cluster-remote.yaml](./cluster-remote.yaml) - Remote cluster configuration

### Multi-Region Supercluster

**Scenario**: Three-region deployment (US East, US West, EU Central)

- [us-east.yaml](./us-east.yaml) - US East region cluster
- [us-west.yaml](./us-west.yaml) - US West region cluster  
- [eu-central.yaml](./eu-central.yaml) - EU Central region cluster

## Prerequisites

1. **DNS Resolution**: Each cluster must be able to resolve the advertise addresses of other clusters
2. **Network Connectivity**: Gateway port (default 7222) must be accessible between clusters
3. **Load Balancer**: External access to gateway ports (typically via LoadBalancer services)

## Deployment Steps

1. Deploy the platform-core chart with gateway configuration in each cluster
2. Ensure external connectivity is established (LoadBalancer services, DNS, etc.)
3. Verify gateway connectivity using NATS Box or monitoring tools

## Testing Connectivity

Once deployed, you can test cross-cluster connectivity:

```bash
# Connect to NATS Box in cluster 1
kubectl exec -it deployment/nats-box -n nats -- nats pub test.subject "Hello from cluster 1"

# Subscribe from NATS Box in cluster 2  
kubectl exec -it deployment/nats-box -n nats -- nats sub test.subject
```

## Monitoring

Monitor gateway connectivity through:
- NATS server monitoring endpoints
- Gateway connection logs
- Cross-cluster message flow metrics
