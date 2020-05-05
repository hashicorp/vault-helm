#!/usr/bin/env bats

load _helpers

@test "injector/PodSecurityPolicy-Role: PodSecurityPolicy-Role not enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-psp-role.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PodSecurityPolicy-Role: enable with injector.enabled and global.pspEnable" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-psp-role.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PodSecurityPolicy-Role: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-psp-role.yaml  \
      --set 'global.enabled=false' \
      --set 'injector.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}