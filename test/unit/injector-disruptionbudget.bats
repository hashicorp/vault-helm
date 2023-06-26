#!/usr/bin/env bats

load _helpers

@test "injector/DisruptionBudget: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-disruptionbudget.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/DisruptionBudget: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-disruptionbudget.yaml \
      --set 'injector.podDisruptionBudget.minAvailable=2' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/injector-disruptionbudget.yaml \
      --set 'injector.podDisruptionBudget.minAvailable=2' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "injector/DisruptionBudget: configure with injector.podDisruptionBudget minAvailable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-disruptionbudget.yaml \
      --set 'injector.podDisruptionBudget.minAvailable=2' \
      . | tee /dev/stderr |
      yq '.spec.minAvailable == 2' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/DisruptionBudget: configure with injector.podDisruptionBudget maxUnavailable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-disruptionbudget.yaml \
      --set 'injector.podDisruptionBudget.maxUnavailable=3' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable == 3' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/DisruptionBudget: apiVersion is set correctly >= version 1.21 of kube" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-disruptionbudget.yaml \
      --set 'injector.podDisruptionBudget.minAvailable=2' \
      --kube-version 1.22.5 \
      . | tee /dev/stderr |
      yq '.apiVersion == "policy/v1"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
