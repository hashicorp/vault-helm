#!/usr/bin/env bats

load _helpers

@test "injector/ServiceAccount: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/ServiceAccount: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# extra labels

@test "injector/ServiceAccount: specify extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml \
      --set 'injector.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}
