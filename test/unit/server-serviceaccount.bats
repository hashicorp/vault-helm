#!/usr/bin/env bats

load _helpers

@test "server/ServiceAccount: specify service account name" {
  cd `chart_dir`

  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.enabled=false' \
      . | tee /dev/stderr |
      yq 'length == 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.name=user-defined-ksa' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "user-defined-ksa" ]

  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]

  local actual=$(helm template \
      -x templates/server-serviceaccount.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.serviceAccount.annotations.iam\.gke\.io/gcp-service-account=user-defined-gsa@my-project.iam.gserviceaccount.com' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["iam.gke.io/gcp-service-account"]' | tee /dev/stderr)
  [ "${actual}" = "user-defined-gsa@my-project.iam.gserviceaccount.com" ]
}

@test "server/ServiceAccount: specify annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.serviceAccount.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.serviceAccount.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["foo"]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ServiceAccount: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ServiceAccount: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-service.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-service.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-service.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
