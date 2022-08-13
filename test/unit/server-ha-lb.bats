#!/usr/bin/env bats

load _helpers

@test "server/ha-lb-Service: generic annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'server.ha.lb.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-lb-Service: disable with ha.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-ha-lb.yaml  \
      --set 'server.ha.enabled=false' \
      --set 'server.ha.lb.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-lb-Service: disable with ha.lb.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-ha-lb.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-lb-Service: disable with server.service.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-ha-lb.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'server.service.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-lb-Service: type LoadBalancer" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]
}

@test "server/ha-lb-Service: clusterIP empty by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.clusterIP' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-lb-Service: externalTrafficPolicy Local and publishNotReadyAddresses false as defaults" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Local" ]

  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-lb-Service: externalTrafficPolicy can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'server.ha.lb.externalTrafficPolicy=Cluster' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Cluster" ]
}

@test "server/ha-lb-Service: publishNotReadyAddresses can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'server.ha.lb.publishNotReadyAddresses=true' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-lb-Service: port and targetPort will be 8200 by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].port' | tee /dev/stderr)
  [ "${actual}" = "8200" ]

  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8200" ]
}

@test "server/ha-lb-Service: https-internal port and targetPort will be 8201" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[1].name' | tee /dev/stderr)
  [ "${actual}" = "https-internal" ]
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[1].port' | tee /dev/stderr)
  [ "${actual}" = "8201" ]

  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[1].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8201" ]
}

@test "server/ha-lb-Service: https-rep port and targetPort will be 8202" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[2].name' | tee /dev/stderr)
  [ "${actual}" = "https-rep" ]
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[2].port' | tee /dev/stderr)
  [ "${actual}" = "8202" ]

  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[2].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8202" ]
}

@test "server/ha-lb-Service: port and targetPort can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'server.service.port=8000' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].port' | tee /dev/stderr)
  [ "${actual}" = "8000" ]

  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'server.service.targetPort=80' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "80" ]
}

@test "server/ha-lb-Service: vault port name is http, when tlsDisable is true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'global.tlsDisable=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports | map(select(.port==8200)) | .[] .name' | tee /dev/stderr)
  [ "${actual}" = "http" ]
}

@test "server/ha-lb-Service: vault port name is https, when tlsDisable is false" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ha-lb.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.lb.enabled=true' \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.spec.ports | map(select(.port==8200)) | .[] .name' | tee /dev/stderr)
  [ "${actual}" = "https" ]
}
