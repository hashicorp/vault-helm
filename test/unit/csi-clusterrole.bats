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
  [ "${actual}" = "release-name-vault-csi-provider-clusterrole" ]
}

@test "csi/ClusterRole: rules" {
  cd `chart_dir`
  local rules=$(helm template \
      --show-only templates/csi-clusterrole.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq '.rules' | tee /dev/stderr)
  local actual=$(echo "${rules}" | yq 'length')
  [ "${actual}" = "2" ]

  # Create service account tokens for the requesting pod.
  actual=$(echo "${rules}" | yq -c '.[0].apiGroups')
  [ "${actual}" = '[""]' ]
  actual=$(echo "${rules}" | yq -c '.[0].resources')
  [ "${actual}" = '["serviceaccounts/token"]' ]
  actual=$(echo "${rules}" | yq -c '.[0].verbs')
  [ "${actual}" = '["create"]' ]

  # Read the IAM role annotation on the requesting pod's service account for
  # the "aws" auth type.
  actual=$(echo "${rules}" | yq -c '.[1].apiGroups')
  [ "${actual}" = '[""]' ]
  actual=$(echo "${rules}" | yq -c '.[1].resources')
  [ "${actual}" = '["serviceaccounts"]' ]
  actual=$(echo "${rules}" | yq -c '.[1].verbs')
  [ "${actual}" = '["get"]' ]
}
