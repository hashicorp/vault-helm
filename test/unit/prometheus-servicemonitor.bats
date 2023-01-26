#!/usr/bin/env bats

load _helpers

@test "prometheus/ServiceMonitor-server: assertDisabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/ServiceMonitor-server: assertEnabled global" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      --set 'serverTelemetry.serviceMonitor.enabled=false' \
      --set 'global.serverTelemetry.prometheusOperator=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "prometheus/ServiceMonitor-server: assertEnabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "prometheus/ServiceMonitor-server: assertScrapeTimeout default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr |
      yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "${actual}" = "10s" ]
}

@test "prometheus/ServiceMonitor-server: assertScrapeTimeout update" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.scrapeTimeout=60s' \
      . ) | tee /dev/stderr |
      yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "${actual}" = "60s" ]
}

@test "prometheus/ServiceMonitor-server: assertInterval default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr |
      yq -r '.spec.endpoints[0].interval' | tee /dev/stderr)
  [ "${actual}" = "30s" ]
}

@test "prometheus/ServiceMonitor-server: assertInterval update" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.interval=60s' \
      . )  | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].interval')" = "60s" ]
}

@test "prometheus/ServiceMonitor-server: assertSelectors default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.metadata.labels | length')" = "5" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.release')" = "prometheus" ]
}

@test "prometheus/ServiceMonitor-server: assertSelectors override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.selectors.baz=qux' \
      --set 'serverTelemetry.serviceMonitor.selectors.bar=foo' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.metadata.labels | length')" = "6" ]
  [ "$(echo "$output" | yq -r '.metadata.labels | has("app")')" = "false" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.baz')" = "qux" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.bar')" = "foo" ]
}

@test "prometheus/ServiceMonitor-server: assertEndpoints noTLS" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'global.tlsDisable=true' \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].port')" = "http" ]
}

@test "prometheus/ServiceMonitor-server: assertEndpoints TLS" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'global.tlsDisable=false' \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].port')" = "https" ]
}

@test "prometheus/ServiceMonitor-server: assertMetricRelabelings default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0] | has("metricRelabelings")')" = "false" ]
}

@test "prometheus/ServiceMonitor-server: assertMetricRelabelings override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.metricRelabelings[0]=foo' \
      --set 'serverTelemetry.serviceMonitor.metricRelabelings[1]=foo' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0] | has("metricRelabelings")')" = "true" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings | length')" = "2" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings[0]')" = "foo" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings[1]')" = "foo" ]
}

@test "prometheus/ServiceMonitor-server: assertRelabelings default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0] | has("relabelings")')" = "false" ]
}

@test "prometheus/ServiceMonitor-server: assertRelabelings override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.relabelings[0]=foo' \
      --set 'serverTelemetry.serviceMonitor.relabelings[1]=foo' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0] | has("relabelings")')" = "true" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].relabelings | length')" = "2" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].relabelings[0]')" = "foo" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].relabelings[1]')" = "foo" ]
}
