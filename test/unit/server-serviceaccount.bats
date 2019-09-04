#!/usr/bin/env bats

load _helpers

@test "server/ServiceAccount: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceaccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.serviceaccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}
