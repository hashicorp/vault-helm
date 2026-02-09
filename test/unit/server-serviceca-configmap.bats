#!/usr/bin/env bats

load _helpers

@test "server/serviceCA ConfigMap: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/serviceCA ConfigMap: not created when only global.openshift=true" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/serviceCA ConfigMap: not created when only server.serviceCA.enabled=true" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'server.serviceCA.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/serviceCA ConfigMap: created when both flags are true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      --set 'server.serviceCA.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/serviceCA ConfigMap: has correct annotation" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      --set 'server.serviceCA.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["service.beta.openshift.io/inject-cabundle"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/serviceCA ConfigMap: uses default name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      --set 'server.serviceCA.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "service-ca-bundle" ]
}

@test "server/serviceCA ConfigMap: name is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      --set 'server.serviceCA.enabled=true' \
      --set 'server.serviceCA.configMapName=custom-ca-bundle' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "custom-ca-bundle" ]
}

@test "server/serviceCA ConfigMap: has correct labels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      --set 'server.serviceCA.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels["app.kubernetes.io/name"]' | tee /dev/stderr)
  [ "${actual}" = "vault" ]
}

@test "server/serviceCA ConfigMap: has empty data" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-serviceca-configmap.yaml \
      --set 'global.openshift=true' \
      --set 'server.serviceCA.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.data' | tee /dev/stderr)
  [ "${actual}" = "{}" ]
}

