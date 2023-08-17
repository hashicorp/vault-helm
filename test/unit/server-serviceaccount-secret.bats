#!/usr/bin/env bats

load _helpers

@test "server/ServiceAccountSecret: verify service account name match" {
  cd `chart_dir`

  local actual=$( (helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.create=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.name=user-defined-ksa' \
      --set 'server.serviceAccount.createSecret=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "user-defined-ksa-token" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.createSecret=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-token" ]

}

@test "server/ServiceAccountSecret: annotation mapping to service account" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.name=user-defined-ksa' \
      --set 'server.serviceAccount.createSecret=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/service-account.name"]' | tee /dev/stderr)
  [ "${actual}" = "user-defined-ksa" ]

  local actual=$(helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'server.serviceAccount.createSecret=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/service-account.name"]' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]

}

@test "server/ServiceAccountSecret: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.serviceAccount.create=true' \
      --set 'server.serviceAccount.createSecret=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-serviceaccount-secret.yaml  \
      --set 'server.serviceAccount.create=true' \
      --set 'server.serviceAccount.createSecret=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

