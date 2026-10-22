#!/usr/bin/env bats
#
# Acceptance tests for templates/proxy-ingress.yaml
#
# Tests install the chart on a k8s cluster and assert the Ingress object is
# created with the correct spec. No ingress controller is required: the API
# server admits an Ingress with no matching IngressClass, so these tests
# verify that what the chart renders survives real API server validation,
# which helm template alone cannot show.

load _helpers

# ---- helpers ----------------------------------------------------------------

ingress_field() {
  kubectl get ingress "$(name_prefix)-proxy" --output json | jq -r "$1"
}

install_with_ingress() {
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set='server.dev.enabled=true' \
    --set='injector.enabled=false' \
    --set='proxy.enabled=true' \
    --set='proxy.ingress.enabled=true' \
    "$@"
}

# ---- tests ------------------------------------------------------------------

@test "proxy/ingress: Ingress resource is created in the correct namespace" {
  cd `chart_dir`

  install_with_ingress

  local namespace=$(ingress_field '.metadata.namespace')
  [ "${namespace}" == "acceptance" ]
}

@test "proxy/ingress: backend points at the proxy service and port" {
  cd `chart_dir`

  install_with_ingress \
    --set 'proxy.ingress.hosts[0].host=proxy.example.com' \
    --set 'proxy.ingress.hosts[0].paths[0]=/v1'

  local host=$(ingress_field '.spec.rules[0].host')
  [ "${host}" == "proxy.example.com" ]

  local path=$(ingress_field '.spec.rules[0].http.paths[0].path')
  [ "${path}" == "/v1" ]

  local backend=$(ingress_field '.spec.rules[0].http.paths[0].backend.service.name')
  [ "${backend}" == "$(name_prefix)-proxy" ]

  local port=$(ingress_field '.spec.rules[0].http.paths[0].backend.service.port.number')
  [ "${port}" == "8100" ]

  # The backend must resolve to a Service that actually exists, otherwise the
  # Ingress is admitted but can never route
  local service=$(kubectl get service "$(name_prefix)-proxy" --output json | jq -r '.metadata.name')
  [ "${service}" == "$(name_prefix)-proxy" ]
}

@test "proxy/ingress: ingressClassName and tls are set on the Ingress" {
  cd `chart_dir`

  install_with_ingress \
    --set 'proxy.ingress.ingressClassName=nginx' \
    --set 'proxy.ingress.hosts[0].host=proxy.example.com' \
    --set 'proxy.ingress.tls[0].secretName=proxy-tls' \
    --set 'proxy.ingress.tls[0].hosts[0]=proxy.example.com'

  local class=$(ingress_field '.spec.ingressClassName')
  [ "${class}" == "nginx" ]

  local secret=$(ingress_field '.spec.tls[0].secretName')
  [ "${secret}" == "proxy-tls" ]

  local tlsHost=$(ingress_field '.spec.tls[0].hosts[0]')
  [ "${tlsHost}" == "proxy.example.com" ]
}

@test "proxy/ingress: Ingress is not created when the proxy is enabled but the ingress is not" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set='server.dev.enabled=true' \
    --set='injector.enabled=false' \
    --set='proxy.enabled=true'

  local count=$(kubectl get ingress --output json | jq '.items | length')
  [ "${count}" == "0" ]
}

# ---- teardown ---------------------------------------------------------------

teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]; then
    echo "proxy/ingress teardown"
    helm delete "$(name_prefix)" --ignore-not-found
    kubectl delete --all pvc
    kubectl delete namespace acceptance --ignore-not-found=true
    kubectl config unset contexts."$(kubectl config current-context)".namespace
  fi
}
