#!/usr/bin/env bats

load _helpers

@test "injector/ClusterRole: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/ClusterRole: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-clusterrole.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/ClusterRole: no nodes permissions when replicas=1" {
  cd `chart_dir`
  local rules=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      --set 'injector.replicas=1' \
      . | tee /dev/stderr |
      yq '.rules' | tee /dev/stderr)
  rules_length=$(echo "${rules}" | yq 'length')
  [ "${rules_length}" = "1" ]
  resources_length=$(echo "${rules}" | yq '.[0].resources | length')
  [ "${resources_length}" = "1" ]
  resource=$(echo "${rules}" | yq -r '.[0].resources[0]')
  [ "${resource}" = "mutatingwebhookconfigurations" ]
}

@test "injector/ClusterRole: nodes permissions when replicas=2" {
  cd `chart_dir`
  local rules=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      --set 'injector.replicas=2' \
      . | tee /dev/stderr |
      yq '.rules' | tee /dev/stderr)
  rules_length=$(echo "${rules}" | yq 'length')
  [ "${rules_length}" = "2" ]
  resources_length=$(echo "${rules}" | yq '.[1].resources | length')
  [ "${resources_length}" = "1" ]
  resource=$(echo "${rules}" | yq -r '.[1].resources[0]')
  [ "${resource}" = "nodes" ]
}

@test "injector/ClusterRole: default webhook verbs" {
  cd `chart_dir`
  local verbs=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      . | tee /dev/stderr |
      yq '.rules[0].verbs' | tee /dev/stderr)

  [ "$(echo "${verbs}" | yq 'length')" = "4" ]
  [ "$(echo "${verbs}" | yq -r '.[0]')" = "get" ]
  [ "$(echo "${verbs}" | yq -r '.[1]')" = "list" ]
  [ "$(echo "${verbs}" | yq -r '.[2]')" = "watch" ]
  [ "$(echo "${verbs}" | yq -r '.[3]')" = "patch" ]
}

@test "injector/ClusterRole: custom webhook verbs" {
  cd `chart_dir`
  local verbs=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      --set 'injector.clusterRole.verbs={get,list}' \
      . | tee /dev/stderr |
      yq '.rules[0].verbs' | tee /dev/stderr)

  [ "$(echo "${verbs}" | yq 'length')" = "2" ]
  [ "$(echo "${verbs}" | yq -r '.[0]')" = "get" ]
  [ "$(echo "${verbs}" | yq -r '.[1]')" = "list" ]
}

@test "injector/ClusterRole: default webhook apiGroups" {
  cd `chart_dir`
  local apiGroups=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      . | tee /dev/stderr |
      yq '.rules[0].apiGroups' | tee /dev/stderr)

  [ "$(echo "${apiGroups}" | yq 'length')" = "1" ]
  [ "$(echo "${apiGroups}" | yq -r '.[0]')" = "admissionregistration.k8s.io" ]
}

@test "injector/ClusterRole: custom webhook apiGroups" {
  cd `chart_dir`
  local apiGroups=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      --set 'injector.clusterRole.apiGroups={admissionregistration.k8s.io,apps}' \
      . | tee /dev/stderr |
      yq '.rules[0].apiGroups' | tee /dev/stderr)

  [ "$(echo "${apiGroups}" | yq 'length')" = "2" ]
  [ "$(echo "${apiGroups}" | yq -r '.[0]')" = "admissionregistration.k8s.io" ]
  [ "$(echo "${apiGroups}" | yq -r '.[1]')" = "apps" ]
}

@test "injector/ClusterRole: default webhook resources" {
  cd `chart_dir`
  local resources=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      . | tee /dev/stderr |
      yq '.rules[0].resources' | tee /dev/stderr)

  [ "$(echo "${resources}" | yq 'length')" = "1" ]
  [ "$(echo "${resources}" | yq -r '.[0]')" = "mutatingwebhookconfigurations" ]
}

@test "injector/ClusterRole: custom webhook resources" {
  cd `chart_dir`
  local resources=$(helm template \
      --show-only templates/injector-clusterrole.yaml  \
      --set 'injector.clusterRole.resources={mutatingwebhookconfigurations,validatingwebhookconfigurations}' \
      . | tee /dev/stderr |
      yq '.rules[0].resources' | tee /dev/stderr)

  [ "$(echo "${resources}" | yq 'length')" = "2" ]
  [ "$(echo "${resources}" | yq -r '.[0]')" = "mutatingwebhookconfigurations" ]
  [ "$(echo "${resources}" | yq -r '.[1]')" = "validatingwebhookconfigurations" ]
}

