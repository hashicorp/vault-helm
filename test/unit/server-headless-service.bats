#!/usr/bin/env bats

load _helpers

@test "server/headless-Service: publishNotReadyAddresses can be changed" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.service.publishNotReadyAddresses=false' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
