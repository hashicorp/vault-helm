#!/usr/bin/env bats

load _helpers

@test "dns/Service: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/dns-service.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "dns/Service: enable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/dns-service.yaml  \
      --set 'global.enabled=false' \
      --set 'dns.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "dns/Service: disable with dns.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/dns-service.yaml  \
      --set 'dns.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "dns/Service: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/dns-service.yaml  \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
