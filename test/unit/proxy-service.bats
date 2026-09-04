#!/usr/bin/env bats

load _helpers

@test "proxy/Service: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-service.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Service: enabled with proxy.enabled=true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/Service: disable with proxy.service.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Service: default type and ports" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.type')" = "ClusterIP" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].port')" = "8100" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].targetPort')" = "8100" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].name')" = "proxy" ]
}

@test "proxy/Service: custom type and ports" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.type=NodePort' \
      --set 'proxy.service.port=8300' \
      --set 'proxy.service.targetPort=8300' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.type')" = "NodePort" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].port')" = "8300" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].targetPort')" = "8300" ]
}

@test "proxy/Service: no externalTrafficPolicy for ClusterIP" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalTrafficPolicy=Local' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/Service: specify externalTrafficPolicy with LoadBalancer" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.type=LoadBalancer' \
      --set 'proxy.service.externalTrafficPolicy=Local' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Local" ]
}

@test "proxy/Service: specify nodePort with NodePort type" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.type=NodePort' \
      --set 'proxy.service.nodePort=30100' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].nodePort' | tee /dev/stderr)
  [ "${actual}" = "30100" ]
}

@test "proxy/Service: nodePort ignored for ClusterIP" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.nodePort=30100' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].nodePort' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/Service: selector targets the proxy pods" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.selector["app.kubernetes.io/name"]')" = "vault-proxy" ]
  [ "$(echo "$output" | yq -r '.spec.selector.component')" = "proxy" ]
}

@test "proxy/Service: no annotations by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/Service: specify annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/Service: specify annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}
