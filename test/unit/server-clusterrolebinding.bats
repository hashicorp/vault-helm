#!/usr/bin/env bats

load _helpers

@test "server/ClusterRoleBinding: enabled by default" {
  cd `chart_dir`
  run helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      .
  [ "$status" -eq 1 ]

  run helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      .
  [ "$status" -eq 1 ]

  run helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      .
  [ "$status" -eq 1 ]
}

@test "server/ClusterRoleBinding: disable with global.enabled" {
  cd `chart_dir`
  run helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'global.enabled=false' \
      .
  [ "$status" -eq 1 ]
}

@test "server/ClusterRoleBinding: can disable with server.authDelegator" {
  cd `chart_dir`
  local actual=$(helm template \
     --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=true' \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/server-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
