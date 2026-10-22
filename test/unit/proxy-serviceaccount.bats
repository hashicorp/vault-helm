#!/usr/bin/env bats

load _helpers

@test "proxy/ServiceAccount: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/ServiceAccount: enabled with proxy.enabled=true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/ServiceAccount: disable with serviceAccount.create false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.create=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/ServiceAccount: default name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-proxy" ]
}

@test "proxy/ServiceAccount: specify name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.name=custom-proxy-sa' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "custom-proxy-sa" ]
}

@test "proxy/ServiceAccount: specify annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/ServiceAccount: specify annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/ServiceAccount: specify extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-serviceaccount.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}
