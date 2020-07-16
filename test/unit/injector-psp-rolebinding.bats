#!/usr/bin/env bats

load _helpers

@test "injector/PodSecurityPolicy-RoleBinding: PodSecurityPolicy-RoleBinding not enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-psp-rolebinding.yaml  \
      . || echo "---" ) | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PodSecurityPolicy-RoleBinding: enable with injector.enabled and global.psp.enable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-psp-rolebinding.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PodSecurityPolicy-RoleBinding: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-psp-rolebinding.yaml  \
      --set 'global.enabled=false' \
      --set 'injector.enabled=true' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
