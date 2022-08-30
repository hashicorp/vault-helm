#!/usr/bin/env bats

load _helpers

@test "prometheus/ServiceMonitor: assertDisabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "prometheus/ServiceMonitor: assertEnabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml  \
      --set 'telemetry.prometheusOperator.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "prometheus/ServiceMonitor: assertScrapeTimeout default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'telemetry.prometheusOperator.enabled=true' \
      . ) | tee /dev/stderr |
      yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "${actual}" = "10s" ]
}

@test "prometheus/ServiceMonitor: assertScrapeTimeout update" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'telemetry.prometheusOperator.enabled=true' \
      --set 'telemetry.prometheusOperator.serviceMonitor.scrapeTimeout=60s' \
      . ) | tee /dev/stderr |
      yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "${actual}" = "60s" ]
}

@test "prometheus/ServiceMonitor: assertInterval default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'telemetry.prometheusOperator.enabled=true' \
      . ) | tee /dev/stderr |
      yq -r '.spec.endpoints[0].interval' | tee /dev/stderr)
  [ "${actual}" = "30s" ]
}

@test "prometheus/ServiceMonitor: assertInterval update" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'telemetry.prometheusOperator.enabled=true' \
      --set 'telemetry.prometheusOperator.serviceMonitor.interval=60s' \
      . )  | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].interval')" = "60s" ]
}

@test "prometheus/ServiceMonitor: assertSelectors default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'telemetry.prometheusOperator.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.metadata.labels | length')" = "5" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.release')" = "prometheus" ]
}

@test "prometheus/ServiceMonitor: assertSelectors overrides" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'telemetry.prometheusOperator.enabled=true' \
      --set 'telemetry.prometheusOperator.enabled=true' \
      --set 'telemetry.prometheusOperator.serviceMonitor.overrideSelectors.baz=qux' \
      --set 'telemetry.prometheusOperator.serviceMonitor.overrideSelectors.bar=foo' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.metadata.labels | length')" = "6" ]
  [ "$(echo "$output" | yq -r '.metadata.labels | has("app")')" = "false" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.baz')" = "qux" ]
  [ "$(echo "$output" | yq -r '.metadata.labels.bar')" = "foo" ]
}

@test "prometheus/ServiceMonitor: assertEndpoints noTLS" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'global.tlsDisable=true' \
      --set 'telemetry.prometheusOperator.enabled=true' \
      . ) | tee /dev/stderr)

      #yq -r '.spec.endpoints[0].scrapeTimeout' | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].port')" = "http" ]
}

@test "prometheus/ServiceMonitor: assertEndpoints TLS" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'global.tlsDisable=false' \
      --set 'telemetry.prometheusOperator.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints | length')" = "1" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].port')" = "https" ]
}
