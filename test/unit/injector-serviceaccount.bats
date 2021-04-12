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

@test "injector/ServiceAccount: set different serviceAccount name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'injector.serviceAccount.name=foobar' \
      . | tee /dev/stderr |
      yq '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "foobar" ]
}

@test "injector/ServiceAccount: set annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'injector.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]

    local actual=$(helm template \
        --show-only templates/injector-serviceaccount.yaml  \
        --set 'injector.serviceAccount.annotations=foo=bar' \
        . | tee /dev/stderr |
        yq '.metadata.annotations["foo"]' | tee /dev/stderr)
    [ "${actual}" = "bar" ]
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
