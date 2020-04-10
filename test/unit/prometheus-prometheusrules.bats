#!/usr/bin/env bats

load _helpers

@test "prometheus/PrometheusRules: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/PrometheusRules: still disabled with prometheus.operator.prometheusRules.enabled true" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml  \
      --set 'prometheus.operator.prometheusRules.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/PrometheusRules: enabled with prometheus.operator.prometheusRules.enabled true and rules" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml  \
      --set 'prometheus.operator.prometheusRules.enabled=true' \
      --set 'prometheus.operator.prometheusRules.rules={something}' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.spec.groups[0].rules[0]' | tee /dev/stderr)
  [ "${actual}" = "something" ]
}

@test "prometheus/PrometheusRules: specifying prometheus.operator.prometheusRules.selector adds additional labels" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-prometheusrules.yaml \
      --set 'prometheus.operator.prometheusRules.enabled=true' \
      --set 'prometheus.operator.prometheusRules.rules={something}' \
      --set 'prometheus.operator.prometheusRules.selector.newlabel1=foo' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.metadata.labels.newlabel1' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}