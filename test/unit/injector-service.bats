#!/usr/bin/env bats

load _helpers

@test "injector/Service: service enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-service.yaml \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/injector-service.yaml \
      --set 'injector.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/Service: service with default port" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-service.yaml \
      . | tee /dev/stderr |
       yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8080" ]
}

@test "injector/Service: service with custom port" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-service.yaml \
      --set 'injector.port=8443' \
      . | tee /dev/stderr |
       yq -r '.spec.ports[0].targetPort' | tee /dev/stderr)
  [ "${actual}" = "8443" ]
}

@test "injector/Service: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-service.yaml \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-service.yaml \
      --set 'global.enabled=false' \
      --set 'injector.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/Service: generic annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-service.yaml \
      --set 'injector.service.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
