#!/usr/bin/env bats

load _helpers

@test "server/ha-active-Service: generic annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-active-service.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.service.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
