#!/usr/bin/env bats

load _helpers

@test "ui/Service: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/ui-service.yaml \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ui/Service: disable with ui.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ui/Service: 'disable with global, enable with ui.enabled'" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'global.enabled=false' \
      --set 'server.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "ui/Service: disable with injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "ui/Service: ClusterIP type by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "ClusterIP" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "ClusterIP" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "ClusterIP" ]
}

@test "ui/Service: specified type" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.type' | tee /dev/stderr)
  [ "${actual}" = "LoadBalancer" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.externalTrafficPolicy=Local' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Local" ]
}

@test "ui/Service: LoadBalancerIP set if specified and serviceType == LoadBalancer" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.loadBalancerIP=123.123.123.123' \
      . | tee /dev/stderr |
      yq -r '.spec.loadBalancerIP' | tee /dev/stderr)
  [ "${actual}" = "123.123.123.123" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=ClusterIP' \
      --set 'ui.enabled=true' \
      --set 'ui.loadBalancerIP=123.123.123.123' \
      . | tee /dev/stderr |
      yq -r '.spec.loadBalancerIP' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: set loadBalancerSourceRanges when LoadBalancer is configured as serviceType" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.loadBalancerSourceRanges={"123.123.123.123"}' \
      . | tee /dev/stderr |
      yq -r '.spec.loadBalancerSourceRanges[0]' | tee /dev/stderr)
  [ "${actual}" = "123.123.123.123" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=ClusterIP' \
      --set 'ui.enabled=true' \
      --set 'ui.loadBalancerSourceRanges={"123.123.123.123"}' \
      . | tee /dev/stderr |
      yq -r '.spec.loadBalancerSourceRanges[0]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: ClusterIP assert no externalTrafficPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'ui.serviceType=ClusterIP' \
      --set 'ui.externalTrafficPolicy=Foo' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      --set 'ui.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: port name is http, when tlsDisable is true" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/ui-service.yaml \
      --set 'global.tlsDisable=true' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].name' | tee /dev/stderr)
  [ "${actual}" = "http" ]
}

@test "ui/Service: port name is https, when tlsDisable is false" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/ui-service.yaml \
      --set 'global.tlsDisable=false' \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].name' | tee /dev/stderr)
  [ "${actual}" = "https" ]
}

@test "ui/Service: publishNotReadyAddresses set true by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "ui/Service: publishNotReadyAddresses can be set to false" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'ui.publishNotReadyAddresses=false' \
      . | tee /dev/stderr |
      yq -r '.spec.publishNotReadyAddresses' | tee /dev/stderr)
  [ "${actual}" = 'false' ]
}

@test "ui/Service: active pod only selector not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.selector["vault-active"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: active pod only selector can be set on HA" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'ui.activeVaultPodOnly=true' \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.selector["vault-active"]' | tee /dev/stderr)
  [ "${actual}" = 'null' ]

  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'ui.activeVaultPodOnly=true' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.selector["vault-active"]' | tee /dev/stderr)
  [ "${actual}" = 'true' ]
}

@test "ui/Service: default is no nodePort" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/ui-service.yaml \
      --set 'ui.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].nodePort' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: can set nodePort" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/ui-service.yaml \
      --set 'ui.enabled=true' \
      --set 'ui.serviceNodePort=123' \
      . | tee /dev/stderr |
      yq -r '.spec.ports[0].nodePort' | tee /dev/stderr)
  [ "${actual}" = "123" ]
}

@test "ui/Service: LoadBalancer assert externalTrafficPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'server.standalone.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.externalTrafficPolicy=Foo' \
      . | tee /dev/stderr |
      yq -r '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "Foo" ]
}

@test "ui/Service: LoadBalancer assert no externalTrafficPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'server.standalone.enabled=true' \
      --set 'ui.serviceType=LoadBalancer' \
      --set 'ui.externalTrafficPolicy=' \
      . | tee /dev/stderr |
      yq '.spec.externalTrafficPolicy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "ui/Service: Assert ipFamilies set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'ui.serviceIPFamilies={IPv4,IPv6}' \
      . | tee /dev/stderr |
      yq '.spec.ipFamilies' -c | tee /dev/stderr)
  [ "${actual}" = '["IPv4","IPv6"]' ]
}

@test "ui/Service: Assert ipFamilyPolicy set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml  \
      --set 'ui.enabled=true' \
      --set 'ui.serviceIPFamilyPolicy=PreferDualStack' \
      . | tee /dev/stderr |
      yq -r '.spec.ipFamilyPolicy' | tee /dev/stderr)
  [ "${actual}" = "PreferDualStack" ]
}

@test "server/Service: Assert ipFamilyPolicy is not set if version below 1.23" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml \
      --kube-version 1.22.0 \
      --set 'ui.enabled=true' \
      --set 'ui.serviceIPFamilyPolicy=PreferDualStack' \
      . | tee /dev/stderr |
      yq -r '.spec.ipFamilyPolicy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/Service: Assert ipFamilies is not set if version below 1.23" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/ui-service.yaml \
      --kube-version 1.22.0 \
      --set 'ui.enabled=true' \
      --set 'ui.serviceIPFamilies={IPv4,IPv6}' \
      . | tee /dev/stderr |
      yq -r '.spec.ipFamilies' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}