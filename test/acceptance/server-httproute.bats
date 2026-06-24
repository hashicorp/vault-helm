#!/usr/bin/env bats
#
# Acceptance tests for templates/server-httproute.yaml
#
# Tests install the chart on a k8s cluster and assert the HTTPRoute
# object is created with the correct spec. No Gateway or controller is required —
# Kubernetes accepts an HTTPRoute with a parentRef to a non-existent Gateway
# because the Gateway API webhooks validate schema only.
#
# Prerequisites:
#   - Gateway API CRDs installed on the test cluster (tests are skipped otherwise)

load _helpers

setup() {
  kubectl get crd httproutes.gateway.networking.k8s.io &>/dev/null \
    || skip "Gateway API CRDs not installed"
}

# ---- helpers ----------------------------------------------------------------

httproute_field() {
  kubectl get httproute "$(name_prefix)" --output json | jq -r "$1"
}

# ---- tests ------------------------------------------------------------------

@test "server/httproute: HTTPRoute resource is created in the correct namespace" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set 'server.httproute.enabled=true' \
    --set 'server.httproute.parentRefs[0].name=test-gateway'

  local namespace=$(httproute_field '.metadata.namespace')
  [ "${namespace}" == "acceptance" ]
}

@test "server/httproute: parentRefs are set on the HTTPRoute" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set 'server.httproute.enabled=true' \
    --set 'server.httproute.parentRefs[0].name=test-gateway' \
    --set 'server.httproute.parentRefs[0].namespace=acceptance'

  local parentName=$(httproute_field '.spec.parentRefs[0].name')
  [ "${parentName}" == "test-gateway" ]

  local parentNamespace=$(httproute_field '.spec.parentRefs[0].namespace')
  [ "${parentNamespace}" == "acceptance" ]
}

@test "server/httproute: backendRef points to the plain service in standalone mode" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set 'server.httproute.enabled=true' \
    --set 'server.httproute.parentRefs[0].name=test-gateway'

  local backendName=$(httproute_field '.spec.rules[0].backendRefs[0].name')
  [ "${backendName}" == "$(name_prefix)" ]

  local backendPort=$(httproute_field '.spec.rules[0].backendRefs[0].port')
  [ "${backendPort}" == "8200" ]
}

@test "server/httproute: backendRef points to the active service in HA mode" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set 'server.httproute.enabled=true' \
    --set 'server.httproute.parentRefs[0].name=test-gateway' \
    --set 'server.ha.enabled=true' \
    --set 'server.dev.enabled=false'

  local backendName=$(httproute_field '.spec.rules[0].backendRefs[0].name')
  [ "${backendName}" == "$(name_prefix)-active" ]
}

@test "server/httproute: hostname is set on the HTTPRoute when configured" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set 'server.httproute.enabled=true' \
    --set 'server.httproute.parentRefs[0].name=test-gateway' \
    --set 'server.httproute.hostnames[0]=vault.example.com'

  local hostname=$(httproute_field '.spec.hostnames[0]')
  [ "${hostname}" == "vault.example.com" ]
}

@test "server/httproute: custom labels are present on the HTTPRoute" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES} \
    --set 'server.httproute.enabled=true' \
    --set 'server.httproute.parentRefs[0].name=test-gateway' \
    --set 'server.httproute.labels.team=platform'

  local label=$(httproute_field '.metadata.labels.team')
  [ "${label}" == "platform" ]
}

@test "server/httproute: HTTPRoute is not created when disabled" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${SET_CHART_VALUES}

  local count=$(kubectl get httproute --output json | jq '.items | length')
  [ "${count}" == "0" ]
}

# ---- teardown ---------------------------------------------------------------

teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]; then
    echo "server/httproute teardown"
    helm delete "$(name_prefix)" --ignore-not-found
    kubectl delete --all pvc
    kubectl delete namespace acceptance --ignore-not-found=true
    kubectl config unset contexts."$(kubectl config current-context)".namespace
  fi
}
