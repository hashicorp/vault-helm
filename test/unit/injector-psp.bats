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

@test "injector/PodSecurityPolicy: enable with injector.enabled and global.psp.enable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-psp.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.psp.enable=true' \
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
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PodSecurityPolicy: annotations are templated correctly by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-psp.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.metadata.annotations | length == 4' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PodSecurityPolicy: annotations are added - string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-psp.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations=vault-is: amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]
}

@test "injector/PodSecurityPolicy: annotations are added - object" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-psp.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations.vault-is=amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]
}
