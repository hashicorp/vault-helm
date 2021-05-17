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

# ClusterRole name
@test "injector/ClusterRoleBinding: name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-default-agent-injector-binding" ]
}

# ClusterRole name in custom namespace
@test "injector/ClusterRoleBinding: name in custom namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --namespace my-custom-namespace \
      --show-only templates/injector-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-my-custom-namespace-agent-injector-binding" ]
}

# ClusterRoleBinding cluster role ref name
@test "injector/ClusterRoleBinding: cluster role ref name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.roleRef.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-default-agent-injector-clusterrole" ]
}

# ClusterRoleBinding cluster role ref name in custom namespace
@test "injector/ClusterRoleBinding: cluster role ref name in custom namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --namespace my-custom-namespace \
      --show-only templates/injector-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.roleRef.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-my-custom-namespace-agent-injector-clusterrole" ]
}
