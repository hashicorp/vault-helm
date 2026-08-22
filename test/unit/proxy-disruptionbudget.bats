#!/usr/bin/env bats

load _helpers

@test "proxy/DisruptionBudget: absent by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-disruptionbudget.yaml \
      --set 'proxy.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/DisruptionBudget: absent when proxy is disabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-disruptionbudget.yaml \
      --set 'proxy.podDisruptionBudget.maxUnavailable=1' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/DisruptionBudget: enabled with podDisruptionBudget set" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-disruptionbudget.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.podDisruptionBudget.maxUnavailable=1' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.kind')" = "PodDisruptionBudget" ]
  [ "$(echo "$output" | yq -r '.spec.maxUnavailable')" = "1" ]
}

@test "proxy/DisruptionBudget: passes through arbitrary spec fields" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-disruptionbudget.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.podDisruptionBudget.minAvailable=1' \
      . | tee /dev/stderr |
      yq -r '.spec.minAvailable' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "proxy/DisruptionBudget: selector targets the proxy pods" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-disruptionbudget.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.podDisruptionBudget.maxUnavailable=1' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/name"]')" = "vault-proxy" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels.component')" = "proxy" ]
}
