#!/usr/bin/env bats

load _helpers

@test "server/ClusterRoleBinding: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ClusterRoleBinding: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ClusterRoleBinding: can disable with server.authDelegator" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
