#!/bin/bash

# Local CI test script - runs the same tests as CI but without requiring K8s cluster

set -e

echo "🔍 Running local CI tests..."

echo "📦 Setting up Helm..."
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is required but not installed. Please install Helm first."
    exit 1
fi

echo "✅ Helm found: $(helm version --short)"

echo ""
echo "🔍 Running Helm lint..."
helm lint platform-core

echo ""
echo "🔍 Testing basic template generation..."
helm template platform-core platform-core > /dev/null
echo "✅ Basic template generation successful"

echo ""
echo "🔍 Testing different value combinations..."

# Test scenarios
declare -A scenarios=(
    ["minimal"]="global:
  clusterName: test
bootstrap:
  nats:
    enabled: true"
    
    ["monitoring"]="global:
  clusterName: test
bootstrap:
  prometheus:
    enabled: true
  grafana:
    enabled: true
  loki:
    enabled: true
  nats:
    enabled: true"
    
    ["security"]="global:
  clusterName: test
bootstrap:
  clusterIssuer:
    letsencrypt:
      enabled: true
  externalSecretOperator:
    enabled: true
  nats:
    enabled: true"
    
    ["full"]="global:
  clusterName: test
bootstrap:
  clusterIssuer:
    letsencrypt:
      enabled: true
  crossplane:
    enabled: true
  atlas:
    enabled: true
  terraformOperator:
    enabled: true
  externalSecretOperator:
    enabled: true
  prometheus:
    enabled: true
  grafana:
    enabled: true
  loki:
    enabled: true
  nats:
    enabled: true
    gateway:
      enabled: true
      name: test-cluster
      port: 7222"
)

for scenario in "${!scenarios[@]}"; do
    echo "  🧪 Testing $scenario configuration..."
    
    # Create temporary values file
    cat > "test-values-$scenario.yaml" << EOF
${scenarios[$scenario]}
EOF
    
    # Test template generation
    helm template platform-core platform-core -f "test-values-$scenario.yaml" > /dev/null
    
    # Test lint with values
    helm lint platform-core -f "test-values-$scenario.yaml" > /dev/null
    
    echo "  ✅ $scenario configuration test passed"
    
    # Clean up
    rm -f "test-values-$scenario.yaml"
done

echo ""
echo "📦 Testing chart packaging..."
helm package platform-core > /dev/null
echo "✅ Chart packaging successful"

# Clean up package
rm -f platform-core-*.tgz

echo ""
echo "🎉 All local CI tests passed!"
echo ""
echo "💡 To run tests with Kubernetes validation (including ArgoCD):"
echo "   task ci-full       # Full CI with K8s cluster, ArgoCD, and cert-manager"
echo "   task dev-full      # Development setup + all tests"
echo ""
echo "🔧 For development:"
echo "   task dev           # Sets up local cluster with ArgoCD and cert-manager"
