#!/usr/bin/env bats

load _helpers

@test "prometheus/PrometheusRules-server: assertDisabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml  \
      --set 'serverTelemetry.prometheusRules.rules[0].foo=bar' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/PrometheusRules-server: assertDisabled with rules-defined=false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml  \
      --set 'serverTelemetry.prometheusRules.enabled=true' \
      . || echo "---") | tee /dev/stderr | yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/PrometheusRules-server: assertEnabled with rules-defined=true" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml \
      --set 'serverTelemetry.prometheusRules.enabled=true' \
      --set 'serverTelemetry.prometheusRules.rules[0].foo=bar' \
      --set 'serverTelemetry.prometheusRules.rules[1].baz=qux' \
      .) | tee  /dev/stderr )

  [ "$(echo "$output" | yq -r '.spec.groups | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.groups[0] | length')" = "2" ]
  [ "$(echo "$output" | yq -r '.spec.groups[0].name')" = "release-name-vault" ]
  [ "$(echo "$output" | yq -r '.spec.groups[0].rules | length')" = "2" ]
  [ "$(echo "$output" | yq -r '.spec.groups[0].rules[0].foo')" = "bar" ]
  [ "$(echo "$output" | yq -r '.spec.groups[0].rules[1].baz')" = "qux" ]
}

@test "prometheus/PrometheusRules-server: assertSelectors default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml \
      --set 'serverTelemetry.prometheusRules.enabled=true' \
      --set 'serverTelemetry.prometheusRules.rules[0].foo=bar' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.metadata.labels | length')" = "5" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.release')" = "prometheus" ]
}

@test "prometheus/PrometheusRules-server: assertSelectors overrides" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml \
      --set 'serverTelemetry.prometheusRules.enabled=true' \
      --set 'serverTelemetry.prometheusRules.rules[0].foo=bar' \
      --set 'serverTelemetry.prometheusRules.selectors.baz=qux' \
      --set 'serverTelemetry.prometheusRules.selectors.bar=foo' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.metadata.labels | length')" = "6" ]
  [ "$(echo "$output" | yq -r '.metadata.labels | has("app")')" = "false" ]
  [ "$(echo "$output" | yq -r '.metadata.labels | has("kube-prometheus-stack")')" = "false" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.baz')" = "qux" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.bar')" = "foo" ]
}
