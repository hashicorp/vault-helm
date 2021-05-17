#!/usr/bin/env bats

load _helpers

@test "server/ClusterRoleBinding: enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ClusterRoleBinding: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# ClusterRole name
@test "server/ClusterRoleBinding: name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-default-server-binding" ]
}

# ClusterRole name in custom namespace
@test "server/ClusterRoleBinding: name in custom namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --namespace my-custom-namespace \
      --show-only templates/server-clusterrolebinding.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-my-custom-namespace-server-binding" ]
}

@test "server/ClusterRoleBinding: can disable with server.authDelegator" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ClusterRoleBinding: also deploy with injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
