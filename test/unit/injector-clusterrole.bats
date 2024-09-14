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
