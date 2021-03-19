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
