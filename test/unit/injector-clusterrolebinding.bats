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

# ClusterRoleBinding service account name
@test "injector/ClusterRoleBinding: service account name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.subjects[0].name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-agent-injector" ]

  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml \
      --set 'injector.serviceAccount.name=user-defined-injector-ksa' \
      . | tee /dev/stderr |
      yq -r '.subjects[0].name' | tee /dev/stderr)
  [ "${actual}" = "user-defined-injector-ksa" ]
}
