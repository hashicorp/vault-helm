#!/usr/bin/env bats

load _helpers

@test "csi/Role: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-role.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "csi/Role: names" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-role.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-csi-provider-role" ]
  local actual=$(helm template \
      --show-only templates/csi-role.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.rules[0].resourceNames[0]' | tee /dev/stderr)
  [ "${actual}" = "vault-csi-provider-hmac-key" ]
}

@test "csi/Role: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-role.yaml \
      --set "csi.enabled=true" \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/csi-role.yaml \
      --set "csi.enabled=true" \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/Role: HMAC secret name configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-role.yaml \
      --set "csi.enabled=true" \
      --set 'csi.hmacSecretName=foo' \
      . | tee /dev/stderr |
      yq -r '.rules[0].resourceNames[0]' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}