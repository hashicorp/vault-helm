#!/usr/bin/env bats

load _helpers

@test "server/network-policy: OpenShift - disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-network-policy.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/network-policy: OpenShift - enabled if OpenShift" {
  cd `chart_dir`
  local actual=$( (helm template \
      --set 'global.openshift=true' \
      --show-only templates/server-network-policy.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}