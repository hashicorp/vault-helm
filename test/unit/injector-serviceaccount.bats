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
      --set 'injector.serviceAccount.name=user-account' \
      . | tee /dev/stderr |
      yq '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "user-account" ]


  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'injector.serviceAccount.create=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-agent-injector" ]
}

@test "injector/ServiceAccount: set annotations" {
  cd `chart_dir`
    local actual=$(helm template \
        --show-only templates/injector-serviceaccount.yaml  \
        --set 'injector.serviceAccount.annotations.foo=bar' \
        . | tee /dev/stderr |
        yq '.metadata.annotations["foo"]' | tee /dev/stderr)
    [ "${actual}" = "bar" ]

    local actual=$(helm template \
        --show-only templates/injector-serviceaccount.yaml  \
        . | tee /dev/stderr |
        yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
    [ "${actual}" = "null" ]

     local actual=$(helm template \
         --show-only templates/injector-serviceaccount.yaml  \
         --set 'injector.serviceAccount.annotations=foo: bar' \
         . | tee /dev/stderr |
         yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
     [ "${actual}" = "bar" ]
}


@test "injector/ServiceAccount: disable with serviceAccount.create" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'injector.serviceAccount.create=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
