#!/usr/bin/env bats

load _helpers

@test "server/namespace-reader/ClusterRoleBinding: enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/namespace-reader/ClusterRoleBinding: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/namespace-reader/ClusterRoleBinding: can disable with server.authDelegator" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/namespace-reader/ClusterRoleBinding: service account namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml \
      --namespace foo \
      . | tee /dev/stderr | \
      yq -r '.subjects[0].namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr | \
      yq -r '.subjects[0].namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/namespace-reader/ClusterRoleBinding: roleRef name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      . | tee /dev/stderr | \
      yq -r '.roleRef.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-namespace-reader" ]
}

@test "server/namespace-reader/ClusterRoleBinding: roleRef kind" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrolebinding.yaml  \
      . | tee /dev/stderr | \
      yq -r '.roleRef.kind' | tee /dev/stderr)
  [ "${actual}" = "ClusterRole" ]
}
