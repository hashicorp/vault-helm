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

@test "prometheus/ServiceMonitor-server: tlsConfig default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].tlsConfig.insecureSkipVerify')" = "true" ]
}

@test "prometheus/ServiceMonitor-server: tlsConfig override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.tlsConfig.ca=ca.crt' \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].tlsConfig.ca')" = "ca.crt" ]
}

@test "prometheus/ServiceMonitor-server: authorization default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].authorization')" = "null" ]
}

@test "prometheus/ServiceMonitor-server: authorization override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.authorization.credentials.name=a-secret' \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].authorization.credentials.name')" = "a-secret" ]
}

@test "prometheus/ServiceMonitor-server: metricRelabelings default" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings')" = "null" ]
}

@test "prometheus/ServiceMonitor-server: metricRelabelings override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.metricRelabelings[0].sourceLabels=[cluster]' \
      --set 'serverTelemetry.serviceMonitor.metricRelabelings[0].targetLabel=vault_cluster' \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings[0] | length')" = "2" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings[0].sourceLabels')" = "[cluster]" ]
  [ "$(echo "$output" | yq -r '.spec.endpoints[0].metricRelabelings[0].targetLabel')" = "vault_cluster" ]
}

@test "prometheus/ServiceMonitor-server: default matchLabels for standalone mode" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["vault-internal"]')" = "true" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/name"]')" = "vault" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/instance"]')" = "release-name" ]
}

@test "prometheus/ServiceMonitor-server: default matchLabels for HA mode" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["vault-active"]')" = "true" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/name"]')" = "vault" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/instance"]')" = "release-name" ]
}

@test "prometheus/ServiceMonitor-server: custom matchLabels for standalone mode" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.component=server' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.service=vault-standalone' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["component"]')" = "server" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["service"]')" = "vault-standalone" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["vault-internal"]')" = "null" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/name"]')" = "vault" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/instance"]')" = "release-name" ]
}

@test "prometheus/ServiceMonitor-server: custom matchLabels for HA mode" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.component=server' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.service=vault-ha' \
      . ) | tee /dev/stderr)

  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["component"]')" = "server" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["service"]')" = "vault-ha" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["vault-active"]')" = "null" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/name"]')" = "vault" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/instance"]')" = "release-name" ]
}

@test "prometheus/ServiceMonitor-server: custom matchLabels with vault-internal override" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.vault-internal=false' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.custom=value' \
      . ) | tee /dev/stderr)

  # Custom labels should be able to override the default label
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["vault-internal"]')" = "false" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["custom"]')" = "value" ]
}

@test "prometheus/ServiceMonitor-server: custom matchLabels with vault-active override in HA mode" {
  cd `chart_dir`
  local output=$( (helm template \
      --show-only templates/prometheus-servicemonitor.yaml \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.vault-active=false' \
      --set 'serverTelemetry.serviceMonitor.matchLabels.custom=value' \
      . ) | tee /dev/stderr)

  # Custom labels should be able to override the default HA label
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["vault-active"]')" = "false" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["custom"]')" = "value" ]
}
