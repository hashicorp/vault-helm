#!/usr/bin/env bats

load _helpers

@test "proxy/ConfigMap: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-configmap.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/ConfigMap: enabled with proxy.enabled=true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/ConfigMap: disabled with global.enabled=false and proxy.enabled=-" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'global.enabled=false' \
      --set 'proxy.enabled=-' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/ConfigMap: enabled with global.enabled=false and proxy.enabled=true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'global.enabled=false' \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/ConfigMap: default vault address is the internal service" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep 'address = "http://release-name-vault.default.svc:8200"'
}

@test "proxy/ConfigMap: vault address respects global.tlsDisable=false" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep 'address = "https://release-name-vault.default.svc:8200"'
}

@test "proxy/ConfigMap: vault address uses global.externalVaultAddr" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      --set 'global.externalVaultAddr=https://vault.example.com:8200' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${actual}" | grep 'address = "https://vault.example.com:8200"'
}

@test "proxy/ConfigMap: default config includes listener and cache stanzas" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  echo "${output}" | grep 'listener "tcp"'
  echo "${output}" | grep 'address = "\[::\]:8100"'
  echo "${output}" | grep 'cache {'
}

@test "proxy/ConfigMap: custom config is templated" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.config=# ns {{ .Release.Namespace }}' \
      . | tee /dev/stderr |
      yq -r '.data["config.hcl"]' | tee /dev/stderr)
  [ "${actual}" = "# ns default" ]
}

@test "proxy/ConfigMap: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "default" ]
  local actual=$(helm template \
      --show-only templates/proxy-configmap.yaml \
      --set 'proxy.enabled=true' \
      --set 'global.namespace=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}
