#!/usr/bin/env bats

load _helpers

@test "server/Service: service enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}


@test "server/Service: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/Service: disable with server.service.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/Service: disable with global.enabled false server.service.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'server.service.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# This can be seen as testing just what we put into the YAML raw, but
# this is such an important part of making everything work we verify it here.
@test "server/Service: tolerates unready endpoints" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["service.alpha.kubernetes.io/tolerate-unready-endpoints"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["service.alpha.kubernetes.io/tolerate-unready-endpoints"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["service.alpha.kubernetes.io/tolerate-unready-endpoints"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/Service: publish not ready" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/Service: clusterIP empty by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/Service: clusterIP can set" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.dev.enabled=true' \
      --set 'server.service.clusterIP=None' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "None" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.service.clusterIP=None' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "None" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.service.clusterIP=None' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "None" ]
}

@test "server/Service: port and targetPort will be 8200 by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].port' | tee /dev/stderr)
  [ "${actual}" = "8200" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8200" ]
}

@test "server/Service: port and targetPort can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.service.port=8000' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].port' | tee /dev/stderr)
  [ "${actual}" = "8000" ]

  local actual=$(helm template \
      -x templates/server-service.yaml \
      --set 'server.service.targetPort=80' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "80" ]
}