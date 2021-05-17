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
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

# ClusterRoleBinding name
@test "csi/ClusterRoleBinding: name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrolebinding.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-default-csi-provider-clusterrolebinding" ]
}

# ClusterRoleBinding name in custom namespace
@test "csi/ClusterRoleBinding: name in custom namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --namespace my-custom-namespace \
      --show-only templates/csi-clusterrolebinding.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-my-custom-namespace-csi-provider-clusterrolebinding" ]
}

# ClusterRoleBinding cluster role ref name
@test "csi/ClusterRoleBinding: cluster role ref name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrolebinding.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.roleRef.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-default-csi-provider-clusterrole" ]
}

# ClusterRoleBinding cluster role ref name in custom namespace
@test "csi/ClusterRoleBinding: cluster role ref name in custom namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --namespace my-custom-namespace \
      --show-only templates/csi-clusterrolebinding.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.roleRef.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-my-custom-namespace-csi-provider-clusterrole" ]
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
