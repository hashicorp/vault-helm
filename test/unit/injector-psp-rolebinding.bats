#!/usr/bin/env bats

load _helpers

@test "injector/PodSecurityPolicy-RoleBinding: PodSecurityPolicy-RoleBinding not enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-psp-rolebinding.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PodSecurityPolicy-RoleBinding: enable with injector.enabled and global.pspEnable" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-psp-rolebinding.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PodSecurityPolicy-RoleBinding: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-psp-rolebinding.yaml  \
      --set 'global.enabled=false' \
      --set 'injector.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
