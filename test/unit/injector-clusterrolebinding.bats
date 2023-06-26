#!/usr/bin/env bats

load _helpers

@test "injector/ClusterRoleBinding: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/ClusterRoleBinding: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-clusterrolebinding.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/ClusterRoleBinding: service account namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml \
      --set "injector.enabled=true" \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.subjects[0].namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml \
      --set "injector.enabled=true" \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.subjects[0].namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}