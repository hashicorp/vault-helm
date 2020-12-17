#!/usr/bin/env bats

load _helpers

@test "injector/deployment: leader elector replica count" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "injector/deployment: leader elector - sidecar is created only when enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.enabled=false" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "injector/deployment: leader elector image name is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.image=SomeOtherImage" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].image' | tee /dev/stderr)
  [ "${actual}" = "SomeOtherImage" ]
}