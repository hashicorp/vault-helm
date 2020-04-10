#!/usr/bin/env bats

load _helpers

@test "prometheus/ServiceMonitor: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/ServiceMonitor: enable with prometheus.operator.enabled true" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      --set 'prometheus.operator.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "prometheus/ServiceMonitor: specifying prometheus.operator.serviceMonitor.selector adds additional labels" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'prometheus.operator.enabled=true' \
      --set 'prometheus.operator.serviceMonitor.selector.newlabel1=foo' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.metadata.labels.newlabel1' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

@test "prometheus/ServiceMonitor: default scrapeTimeout is 10s" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'prometheus.operator.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "${actual}" = "10s" ]
}

@test "prometheus/ServiceMonitor: specifying prometheus.operator.serviceMonitor.scrapeTimeout changes scrapeTimeout" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'prometheus.operator.enabled=true' \
      --set 'prometheus.operator.serviceMonitor.scrapeTimeout=60s' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "${actual}" = "60s" ]
}

@test "prometheus/ServiceMonitor: default interval is 10s" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'prometheus.operator.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.spec.endpoints[0].interval' | tee /dev/stderr)
  [ "${actual}" = "10s" ]
}

@test "prometheus/ServiceMonitor: specifying prometheus.operator.serviceMonitor.interval changes interval" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'prometheus.operator.enabled=true' \
      --set 'prometheus.operator.serviceMonitor.interval=60s' \
      . || echo "---") | tee /dev/stderr |
      yq -r '.spec.endpoints[0].interval' | tee /dev/stderr)
  [ "${actual}" = "60s" ]
}
