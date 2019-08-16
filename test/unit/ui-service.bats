#!/usr/bin/env bats

load _helpers

@test "ui/Service: disabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ui-service.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ui/Service: disable with ui.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ui/Service: disable with ui.service.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ui/Service: ClusterIP type by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "ClusterIP" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "ClusterIP" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "ClusterIP" ]
}

@test "ui/Service: specified type" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]
}

@test "ui/Service: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      -x templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}