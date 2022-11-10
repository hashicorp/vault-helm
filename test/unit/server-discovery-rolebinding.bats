#!/usr/bin/env bats

load _helpers

@test "server/DiscoveryRoleBinding: enabled by default with ha" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-discovery-rolebinding.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-discovery-rolebinding.yaml \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/DiscoveryRoleBinding: can disable with server.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-discovery-rolebinding.yaml \
      --set 'server.enabled=false' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DiscoveryRoleBinding: can disable with server.serviceAccount.create false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-discovery-rolebinding.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.serviceAccount.create=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
