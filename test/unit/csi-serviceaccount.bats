#!/usr/bin/env bats

load _helpers

@test "csi/ServiceAccount: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "csi/ServiceAccount: enable with csi.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/serviceAccount: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'server.serviceAccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}