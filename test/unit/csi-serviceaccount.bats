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

@test "csi/ServiceAccount: enable with csi.enabled and create=true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.create=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/ServiceAccount: Disable with create=false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.create=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# serviceAccountName specify service account name
@test "csi/ServiceAccount: serviceAccountName name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml \
      --set "csi.enabled=true" \
      --set 'csi.serviceAccount.create=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-csi-provider" ]

  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set "csi.enabled=true" \
      --set 'csi.serviceAccount.create=true' \
      --set 'csi.serviceAccount.name=user-defined-csi-ksa' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "user-defined-csi-ksa" ]

}

@test "csi/serviceAccount: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.create=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.create=true' \
      --set 'csi.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/csi-serviceaccount.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.serviceAccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}