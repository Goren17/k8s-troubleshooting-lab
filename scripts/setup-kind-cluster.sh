#!/usr/bin/env bash
set -euo pipefail

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-k8s-troubleshooting-lab}"
LAB_NAMESPACE="${LAB_NAMESPACE:-troubleshooting-lab}"
INGRESS_NGINX_VERSION="${INGRESS_NGINX_VERSION:-controller-v1.12.1}"
METRICS_SERVER_VERSION="${METRICS_SERVER_VERSION:-v0.7.2}"
EXTERNAL_SECRETS_HELM_CHART_VERSION="${EXTERNAL_SECRETS_HELM_CHART_VERSION:-0.10.7}"

WITH_INGRESS=false
WITH_EXTERNAL_SECRETS=false
WITH_METRICS_SERVER=false

usage() {
  cat <<EOF
usage: $0 [--with-ingress] [--with-external-secrets] [--with-metrics-server] [--all-addons]

Creates or reuses a local kind cluster for the troubleshooting lab.

Environment overrides:
  KIND_CLUSTER_NAME=$KIND_CLUSTER_NAME
  LAB_NAMESPACE=$LAB_NAMESPACE
  INGRESS_NGINX_VERSION=$INGRESS_NGINX_VERSION
  METRICS_SERVER_VERSION=$METRICS_SERVER_VERSION
  EXTERNAL_SECRETS_HELM_CHART_VERSION=$EXTERNAL_SECRETS_HELM_CHART_VERSION
EOF
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "missing required command: $command_name" >&2
    exit 1
  fi
}

wait_for_deployment() {
  local namespace="$1"
  local deployment="$2"
  local timeout="${3:-180s}"

  kubectl rollout status "deployment/$deployment" -n "$namespace" --timeout="$timeout"
}

create_kind_config() {
  local config_file="$1"

  cat > "$config_file" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
EOF
}

create_cluster() {
  local config_file

  if kind get clusters | grep -qxF "$KIND_CLUSTER_NAME"; then
    echo "kind cluster already exists: $KIND_CLUSTER_NAME"
    return
  fi

  config_file="$(mktemp)"
  create_kind_config "$config_file"

  echo "Creating kind cluster: $KIND_CLUSTER_NAME"
  kind create cluster --name "$KIND_CLUSTER_NAME" --config "$config_file"
  rm -f "$config_file"
}

create_lab_namespace() {
  kubectl create namespace "$LAB_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

install_ingress_nginx() {
  local manifest_url

  manifest_url="https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml"
  echo "Installing ingress-nginx from $manifest_url"
  kubectl apply -f "$manifest_url"
  wait_for_deployment ingress-nginx ingress-nginx-controller 180s
}

install_metrics_server() {
  local manifest_url

  manifest_url="https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER_VERSION}/components.yaml"
  echo "Installing metrics-server from $manifest_url"
  kubectl apply -f "$manifest_url"
  kubectl patch deployment metrics-server -n kube-system --type=json \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
  wait_for_deployment kube-system metrics-server 180s
}

install_external_secrets() {
  require_command helm

  echo "Installing External Secrets Operator with Helm chart version $EXTERNAL_SECRETS_HELM_CHART_VERSION"
  helm repo add external-secrets https://charts.external-secrets.io >/dev/null
  helm repo update external-secrets >/dev/null
  helm upgrade --install external-secrets external-secrets/external-secrets \
    --namespace external-secrets \
    --create-namespace \
    --version "$EXTERNAL_SECRETS_HELM_CHART_VERSION" \
    --set installCRDs=true
  wait_for_deployment external-secrets external-secrets 180s
  wait_for_deployment external-secrets external-secrets-webhook 180s
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --with-ingress)
      WITH_INGRESS=true
      ;;
    --with-external-secrets)
      WITH_EXTERNAL_SECRETS=true
      ;;
    --with-metrics-server)
      WITH_METRICS_SERVER=true
      ;;
    --all-addons)
      WITH_INGRESS=true
      WITH_EXTERNAL_SECRETS=true
      WITH_METRICS_SERVER=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_command kind
require_command kubectl

create_cluster
kubectl config use-context "kind-$KIND_CLUSTER_NAME"
create_lab_namespace

if [[ "$WITH_INGRESS" == true ]]; then
  install_ingress_nginx
fi

if [[ "$WITH_METRICS_SERVER" == true ]]; then
  install_metrics_server
fi

if [[ "$WITH_EXTERNAL_SECRETS" == true ]]; then
  install_external_secrets
fi

echo
echo "kind cluster is ready: $KIND_CLUSTER_NAME"
echo "namespace is ready: $LAB_NAMESPACE"
echo "next: ./scripts/apply-scenario.sh crashloop-bad-env"

