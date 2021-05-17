#!/usr/bin/env bats

load _helpers

@test "csi/ClusterRole: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-clusterrole.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "csi/ClusterRole: enabled with csi.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrole.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

# ClusterRole name
@test "csi/ClusterRole: name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrole.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-default-csi-provider-clusterrole" ]
}

# ClusterRole name in custom namespace
@test "csi/ClusterRole: name in custom namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --namespace my-custom-namespace \
      --show-only templates/csi-clusterrole.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-my-custom-namespace-csi-provider-clusterrole" ]
}
