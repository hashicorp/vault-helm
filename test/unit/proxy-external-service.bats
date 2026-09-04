#!/usr/bin/env bats

load _helpers

@test "proxy/ExternalService: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-external-service.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/ExternalService: disabled when proxy.enabled=true but externalService.enabled=false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/ExternalService: enabled with proxy.enabled and externalService.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/ExternalService: default type is LoadBalancer" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]
}

@test "proxy/ExternalService: default port and targetPort" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.ports[0].port')" = "8100" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].targetPort')" = "8100" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].name')" = "proxy" ]
}

@test "proxy/ExternalService: custom port and targetPort" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      --set 'proxy.service.externalService.port=8200' \
      --set 'proxy.service.externalService.targetPort=8200' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.ports[0].port')" = "8200" ]
  [ "$(echo "$output" | yq -r '.spec.ports[0].targetPort')" = "8200" ]
}

@test "proxy/ExternalService: service name is <release>-proxy-external" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-proxy-external" ]
}

@test "proxy/ExternalService: selector targets the proxy pods" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.selector["app.kubernetes.io/name"]')" = "vault-proxy" ]
  [ "$(echo "$output" | yq -r '.spec.selector.component')" = "proxy" ]
}

@test "proxy/ExternalService: default externalTrafficPolicy is Local" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Local" ]
}

@test "proxy/ExternalService: externalTrafficPolicy Cluster" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      --set 'proxy.service.externalService.externalTrafficPolicy=Cluster' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Cluster" ]
}

@test "proxy/ExternalService: no externalTrafficPolicy for ClusterIP" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      --set 'proxy.service.externalService.type=ClusterIP' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/ExternalService: loadBalancerSourceRanges" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      --set 'proxy.service.externalService.loadBalancerSourceRanges={10.0.0.0/8,192.168.0.0/16}' \
      . | tee /dev/stderr |
      yq -r '.spec.loadBalancerSourceRanges | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "proxy/ExternalService: no loadBalancerSourceRanges by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.loadBalancerSourceRanges' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/ExternalService: no annotations by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/ExternalService: specify annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      --set 'proxy.service.externalService.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/ExternalService: specify annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-external-service.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.service.externalService.enabled=true' \
      --set 'proxy.service.externalService.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}
