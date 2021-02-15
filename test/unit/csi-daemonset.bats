#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Daemonset

# Enabled
@test "csi/daemonset: created only when enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-daemonset.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# Image
@test "csi/daemonset: image is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.image.repository=SomeOtherImage" \
      --set "csi.image.tag=SomeOtherTag" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "SomeOtherImage:SomeOtherTag" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.image.pullPolicy=SomePullPolicy" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "SomePullPolicy" ]
}

# Debug arg
@test "csi/daemonset: debug arg is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[1]' | tee /dev/stderr)
  [ "${actual}" = "--debug=false" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.debug=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[1]' | tee /dev/stderr)
  [ "${actual}" = "--debug=true" ]
}
