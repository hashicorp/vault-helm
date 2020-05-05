#!/usr/bin/env bats

load _helpers

@test "injector/PodSecurityPolicy: PodSecurityPolicy not enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-psp.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PodSecurityPolicy: enable with injector.enabled and global.pspEnable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-psp.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PodSecurityPolicy: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-psp.yaml  \
      --set 'global.enabled=false' \
      --set 'injector.enabled=true' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
