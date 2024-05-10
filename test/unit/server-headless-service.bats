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

@test "server/headless-Service: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.ha.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/headless-Service: Assert ipFamilyPolicy set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.service.ipFamilyPolicy=PreferDualStack' \
      . | tee /dev/stderr |
      yq -r '.spec.ipFamilyPolicy' | tee /dev/stderr)
  [ "${actual}" = "PreferDualStack" ]
}

@test "server/headless-Service: Assert ipFamilies set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --set 'server.service.ipFamilies={IPv4,IPv6}' \
      . | tee /dev/stderr |
      yq '.spec.ipFamilies' -c | tee /dev/stderr)
  [ "${actual}" = '["IPv4","IPv6"]' ]
}

@test "server/headless-Service: Assert ipFamilyPolicy is not set if version below 1.23" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --kube-version 1.22.0 \
      --set 'server.service.ipFamilyPolicy=PreferDualStack' \
      . | tee /dev/stderr |
      yq -r '.spec.ipFamilyPolicy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/headless-Service: Assert ipFamilies is not set if version below 1.23" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-headless-service.yaml \
      --kube-version 1.22.0 \
      --set 'server.service.ipFamilies={IPv4,IPv6}' \
      . | tee /dev/stderr |
      yq -r '.spec.ipFamilies' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}