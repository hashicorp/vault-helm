#!/usr/bin/env bats

load _helpers

@test "syncCatalog/Deployment: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: enable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'global.enabled=false' \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "syncCatalog/Deployment: disable with syncCatalog.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# toConsul and toK8S

@test "syncCatalog/Deployment: bidirectional by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-consul"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-k8s"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: to-k8s only" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toConsul=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-consul=false"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toConsul=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-k8s"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "syncCatalog/Deployment: to-consul only" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toK8S=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-k8s=false"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/sync-catalog-deployment.yaml  \
      --set 'syncCatalog.enabled=true' \
      --set 'syncCatalog.toK8S=false' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-to-consul"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
