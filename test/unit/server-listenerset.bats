#!/usr/bin/env bats

load _helpers

@test "server/listenerset: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-listenerset.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/listenerset: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/listenerset: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/listenerset: disabled on openshift" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'global.openshift=true' \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/listenerset: fails without parentRef.name" {
  cd `chart_dir`
  run helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.listeners[0].name=vault' \
      .
  [ "$status" -eq 1 ]
  [[ "$output" == *"server.listenerset.parentRef.name must be set"* ]]
}

@test "server/listenerset: fails without listeners" {
  cd `chart_dir`
  run helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      .
  [ "$status" -eq 1 ]
  [[ "$output" == *"server.listenerset.listeners must contain at least one listener"* ]]
}

@test "server/listenerset: parentRef is set" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.parentRef.namespace=gateway-ns' \
      --set 'server.listenerset.listeners[0].name=vault' \
      . | tee /dev/stderr |
      yq -r '.spec.parentRef' | tee /dev/stderr)

  local actual=$(echo $object | yq -r '.name' | tee /dev/stderr)
  [ "${actual}" = "test-gateway" ]
  local actual=$(echo $object | yq -r '.namespace' | tee /dev/stderr)
  [ "${actual}" = "gateway-ns" ]
}

@test "server/listenerset: HTTPS listener with TLS termination" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault-https' \
      --set 'server.listenerset.listeners[0].hostname=vault.example.com' \
      --set 'server.listenerset.listeners[0].port=443' \
      --set 'server.listenerset.listeners[0].protocol=HTTPS' \
      --set 'server.listenerset.listeners[0].tls.mode=Terminate' \
      --set 'server.listenerset.listeners[0].tls.certificateRefs[0].name=vault-tls' \
      . | tee /dev/stderr |
      yq -r '.spec.listeners[0]' | tee /dev/stderr)

  local actual=$(echo $object | yq -r '.name' | tee /dev/stderr)
  [ "${actual}" = "vault-https" ]
  local actual=$(echo $object | yq -r '.hostname' | tee /dev/stderr)
  [ "${actual}" = "vault.example.com" ]
  local actual=$(echo $object | yq -r '.port' | tee /dev/stderr)
  [ "${actual}" = "443" ]
  local actual=$(echo $object | yq -r '.protocol' | tee /dev/stderr)
  [ "${actual}" = "HTTPS" ]
  local actual=$(echo $object | yq -r '.tls.mode' | tee /dev/stderr)
  [ "${actual}" = "Terminate" ]
  local actual=$(echo $object | yq -r '.tls.certificateRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "vault-tls" ]
}

@test "server/listenerset: listener hostname is templated" {
  cd `chart_dir`
  local actual=$(helm template release-name \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --set 'server.listenerset.listeners[0].hostname=vault-{{ .Release.Name }}.example.com' \
      . | tee /dev/stderr |
      yq -r '.spec.listeners[0].hostname' | tee /dev/stderr)
  [ "${actual}" = "vault-release-name.example.com" ]
}

@test "server/listenerset: labels gets added to object" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --set 'server.listenerset.labels.traffic=external' \
      --set 'server.listenerset.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "server/listenerset: annotations added to object - string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --set 'server.listenerset.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/listenerset: annotations added to object - yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-listenerset.yaml  \
      --set 'server.listenerset.enabled=true' \
      --set 'server.listenerset.parentRef.name=test-gateway' \
      --set 'server.listenerset.listeners[0].name=vault' \
      --set server.listenerset.annotations.vaultIsAwesome=true \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
