#!/usr/bin/env bats

load _helpers

@test "server/ha-standby-Service: generic annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-standby-service.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.service.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
