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

@test "injector/ServiceAccount: disable with injector.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'global.enabled=true' \
      --set 'injector.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/ServiceAccount: disable with create=false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'global.enabled=true' \
      --set 'injector.enabled=true' \
      --set 'injector.serviceAccount.create=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# serviceAccountName specify service account name
@test "injector/ServiceAccount: serviceAccountName name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-agent-injector" ]

  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'injector.serviceAccount.name=user-defined-injector-ksa' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "user-defined-injector-ksa" ]

}

@test "injector/ServiceAccount: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'injector.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'global.enabled=true' \
      --set 'injector.enabled=true' \
      --set 'injector.serviceAccount.create=true' \
      --set 'injector.serviceAccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/injector-serviceaccount.yaml  \
      --set 'global.enabled=true' \
      --set 'injector.enabled=true' \
      --set 'injector.serviceAccount.create=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}
