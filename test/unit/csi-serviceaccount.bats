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

# serviceAccountName reference name
@test "csi/daemonset: serviceAccountName name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-csi-provider" ]
}

# serviceAccountNamespace namespace
@test "csi/daemonset: serviceAccountNamespace namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml \
      --set "csi.enabled=true" \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml \
      --set "csi.enabled=true" \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
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

# serviceAccount extraLabels

@test "csi/serviceAccount: specify csi.serviceAccount.extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}


