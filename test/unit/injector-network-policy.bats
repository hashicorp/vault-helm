#!/usr/bin/env bats

load _helpers

@test "injector/network-policy: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-network-policy.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/network-policy: enabled by injector.networkPolicy.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --set 'injector.networkPolicy.enabled=true' \
      --show-only templates/injector-network-policy.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}