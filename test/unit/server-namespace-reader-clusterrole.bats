#!/usr/bin/env bats

load _helpers

@test "server/namespace-reader/ClusterRole: enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/namespace-reader/ClusterRole: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/namespace-reader/ClusterRole: can disable with server.authDelegator" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      --set 'server.authDelegator.enabled=false' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      --set 'server.authDelegator.enabled=false' \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr | \
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/namespace-reader/ClusterRole: rules contain namespaces resource" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      . | tee /dev/stderr | \
      yq -r '.rules[0].resources[0]' | tee /dev/stderr)
  [ "${actual}" = "namespaces" ]
}

@test "server/namespace-reader/ClusterRole: rules contain get verb" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      . | tee /dev/stderr | \
      yq -r '.rules[0].verbs | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      . | tee /dev/stderr | \
      yq -r '.rules[0].verbs[0]' | tee /dev/stderr)
  [ "${actual}" = "get" ]
}

@test "server/namespace-reader/ClusterRole: correct name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-namespace-reader-clusterrole.yaml  \
      . | tee /dev/stderr | \
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-namespace-reader" ]
}
