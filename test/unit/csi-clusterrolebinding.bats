#!/usr/bin/env bats

load _helpers

@test "csi/ClusterRoleBinding: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-clusterrolebinding.yaml  \
      . || echo "---")| tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "csi/ClusterRoleBinding: enabled with csi.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrolebinding.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

# ClusterRoleBinding cluster role ref name
@test "csi/ClusterRoleBinding: cluster role ref name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrolebinding.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.roleRef.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-csi-provider-clusterrole" ]
}

# ClusterRoleBinding service account name
@test "csi/ClusterRoleBinding: service account name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrolebinding.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.subjects[0].name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-csi-provider" ]
}