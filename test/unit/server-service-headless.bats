#!/usr/bin/env bats

load _helpers

@test "server/Service-Headless: headless service enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/Service-Headless: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.headless.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.headless.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.headless.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/Service-Headless: disable with server.service.headless.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.service.headless.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.service.headless.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.service.headless.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/Service-Headless: disable with global.enabled false server.service.headless.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.headless.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.headless.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.headless.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/Service-Headless: clusterIP is None by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "None" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "None" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "None" ]
}

@test "server/Service-Headless: port and targetPort will be 8200 by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].port' | tee /dev/stderr)
  [ "${actual}" = "8200" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8200" ]
}

@test "server/Service-Headless: port and targetPort can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.service.port=8000' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].port' | tee /dev/stderr)
  [ "${actual}" = "8000" ]

  local actual=$(helm template \
      -x templates/server-service-headless.yaml \
      --set 'server.service.targetPort=80' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "80" ]
}
