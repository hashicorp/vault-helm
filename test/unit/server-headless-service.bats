#!/usr/bin/env bats

load _helpers

@test "server/headless-Service: publishNotReadyAddresses cannot be changed" {
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
  [ "${actual}" = "true" ]
}

@test "server/headless-Service: instance selector cannot be disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.selector["app.kubernetes.io/instance"]' | tee /dev/stderr)
  [ "${actual}" = "release-name" ]

  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.service.instanceSelector.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.selector["app.kubernetes.io/instance"]' | tee /dev/stderr)
  [ "${actual}" = "release-name" ]
}
