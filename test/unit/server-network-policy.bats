#!/usr/bin/env bats

load _helpers

@test "server/network-policy: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-network-policy.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/network-policy: enabled by server.networkPolicy.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --set 'server.networkPolicy.enabled=true' \
      --show-only templates/server-network-policy.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/network-policy: egress enabled by server.networkPolicy.egress" {
  cd `chart_dir`
  local actual=$(helm template \
      --set 'server.networkPolicy.enabled=true' \
      --set 'server.networkPolicy.egress=true' \
      --show-only templates/server-network-policy.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.egress[0]' | tee /dev/stderr)
  [ "${actual}" = "{}" ]
}
