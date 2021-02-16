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

@test "csi/ClusterRoleBinding: disabled with csi.enabled if before 0.0.8" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-clusterrolebinding.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.image.tag=0.0.7' \
      . || echo "---")| tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "csi/ClusterRoleBinding: enable with csi.enabled and 0.0.8+" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-clusterrolebinding.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.image.tag=0.0.8' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
