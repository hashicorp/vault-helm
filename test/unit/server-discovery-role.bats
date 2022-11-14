#!/usr/bin/env bats

load _helpers

@test "server/DiscoveryRole: enabled by default with ha" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-discovery-role.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-discovery-role.yaml \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/DiscoveryRole: can disable with server.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-discovery-role.yaml \
      --set 'server.enabled=false' \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DiscoveryRole: can disable with server.serviceAccount.serviceDiscovery.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-discovery-role.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.serviceAccount.serviceDiscovery.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
