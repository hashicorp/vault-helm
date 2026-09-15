#!/usr/bin/env bats

load _helpers

# Renders every resource the chart can produce outside OpenShift.
render_all() {
  helm template vault . \
      --set 'injector.enabled=true' \
      --set 'injector.replicas=2' \
      --set 'injector.podDisruptionBudget.maxUnavailable=1' \
      --set 'csi.enabled=true' \
      --set 'ui.enabled=true' \
      --set 'server.ingress.enabled=true' \
      --set 'server.networkPolicy.enabled=true' \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.serviceAccount.createSecret=true' \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=gw' \
      --set 'global.psp.enable=true' \
      --set 'global.serverTelemetry.prometheusOperator=true' \
      --set-json 'serverTelemetry.prometheusRules.rules=[{"alert":"x","expr":"up"}]' \
      "$@"
}

# Renders the OpenShift-only resources: Route, service-CA ConfigMap and the
# injector NetworkPolicy.
render_openshift() {
  helm template vault . \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.serviceCA.enabled=true' \
      --set 'injector.enabled=true' \
      --set 'csi.enabled=true' \
      "$@"
}

# Together these two cover all 45 templates in the chart.
render_every_template() {
  render_all "$@"
  render_openshift "$@"
}

@test "global/extraLabels: the assertions above cover every template in the chart" {
  cd `chart_dir`
  # If a new template is added but not rendered by the helpers above, the
  # "every resource" assertions would pass while silently skipping it.
  local rendered=$(render_every_template | grep '^# Source:' | sed 's|# Source: vault/templates/||' | sort -u)
  local all=$(ls templates/*.yaml templates/tests/*.yaml | sed 's|templates/||' | sort)

  [ "$(comm -13 <(echo "$rendered") <(echo "$all"))" = "" ]
}

@test "global/extraLabels: not set by default" {
  cd `chart_dir`
  local output=$(render_every_template)

  [ "$(echo "$output" | yq -r 'select(.kind != null) | .metadata.labels.team // "absent"' | sort -u)" = "absent" ]
}

@test "global/extraLabels: applied to metadata.labels of every resource" {
  cd `chart_dir`
  local output=$(render_every_template --set 'global.extraLabels.team=platform')

  # Every rendered resource must carry the label; list any that do not.
  local missing=$(echo "$output" | \
      yq -r 'select(.kind != null) | select(.metadata.labels.team != "platform") | .kind + "/" + .metadata.name')
  [ "${missing}" = "" ]
}

@test "global/extraLabels: applied to pod templates" {
  cd `chart_dir`
  local output=$(render_every_template --set 'global.extraLabels.team=platform')

  local missing=$(echo "$output" | \
      yq -r 'select(.spec.template.metadata != null) | select(.spec.template.metadata.labels.team != "platform") | .kind')
  [ "${missing}" = "" ]
}

@test "global/extraLabels: never added to selectors" {
  cd `chart_dir`
  local output=$(render_every_template --set 'global.extraLabels.team=platform')

  # matchLabels and Service selectors are immutable on an existing install.
  local leaked=$(echo "$output" | \
      yq -r 'select(.spec.selector.matchLabels.team != null) | .kind + "/" + .metadata.name')
  [ "${leaked}" = "" ]

  leaked=$(echo "$output" | \
      yq -r 'select(.kind == "Service") | select(.spec.selector.team != null) | .metadata.name')
  [ "${leaked}" = "" ]
}

@test "global/extraLabels: never added to volumeClaimTemplates" {
  cd `chart_dir`
  # spec.volumeClaimTemplates is immutable on an existing StatefulSet, so
  # labelling it would break helm upgrade.
  local output=$(helm template vault . \
      --set 'server.dataStorage.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'global.extraLabels.team=platform' \
      --show-only templates/server-statefulset.yaml)

  [ "$(echo "$output" | yq -r '.spec.volumeClaimTemplates[0].metadata.labels.team // "absent"')" = "absent" ]
  [ "$(echo "$output" | yq -r '.spec.volumeClaimTemplates[1].metadata.labels.team // "absent"')" = "absent" ]
}

@test "global/extraLabels: per-resource extraLabels take precedence" {
  cd `chart_dir`
  local output=$(helm template vault . \
      --set 'global.extraLabels.env=prod' \
      --set 'server.serviceAccount.extraLabels.env=staging' \
      --show-only templates/server-serviceaccount.yaml)

  [ "$(echo "$output" | yq -r '.metadata.labels.env')" = "staging" ]
}

@test "global/extraLabels: values are quoted so numbers stay strings" {
  cd `chart_dir`
  local output=$(helm template vault . \
      --set 'global.extraLabels.cost-center=1234' \
      --show-only templates/server-service.yaml)

  [ "$(echo "$output" | yq -r '.metadata.labels.cost-center')" = "1234" ]
  echo "$output" | grep -q 'cost-center: "1234"'
}

@test "global/extraLabels: accepts a templated string" {
  cd `chart_dir`
  local output=$(helm template vault . \
      --set 'global.extraLabels=release: {{ .Release.Name }}' \
      --show-only templates/server-service.yaml)

  [ "$(echo "$output" | yq -r '.metadata.labels.release')" = "vault" ]
}

@test "global/extraLabels: fails on malformed YAML instead of rendering an Error label" {
  cd `chart_dir`
  # fromYaml returns an Error key rather than failing, which would otherwise be
  # emitted as a bogus "Error:" label in an invalid manifest.
  run helm template vault . --set 'global.extraLabels=justastring'
  [ "$status" -eq 1 ]
  [[ "$output" =~ "global.extraLabels is not valid YAML" ]]
  [[ ! "$output" =~ "Error: \"error unmarshaling" ]]

  run helm template vault . --set 'global.extraLabels=a: b: c'
  [ "$status" -eq 1 ]
  [[ "$output" =~ "global.extraLabels is not valid YAML" ]]
}

@test "global/extraLabels: fails on a non-scalar value" {
  cd `chart_dir`
  # toString on a map yields Go debug formatting, which is not a valid label.
  run helm template vault . --set 'global.extraLabels.a.b=c'
  [ "$status" -eq 1 ]
  [[ "$output" =~ "must be a scalar value" ]]
  [[ ! "$output" =~ "map[b:c]" ]]
}

@test "global/extraLabels: merges with serverTelemetry selectors without duplicate keys" {
  cd `chart_dir`
  run_case() {
    local template=$1 key=$2
    local output=$(helm template vault . \
        --set 'global.serverTelemetry.prometheusOperator=true' \
        --set 'global.extraLabels.team=platform' \
        --set "serverTelemetry.${key}.selectors.team=other" \
        --set-json 'serverTelemetry.prometheusRules.rules=[{"alert":"x","expr":"up"}]' \
        --show-only templates/$template.yaml)

    # The selector must win, and the key must appear exactly once.
    [ "$(echo "$output" | yq -r '.metadata.labels.team')" = "other" ]
    [ "$(echo "$output" | grep -c '^    team:')" = "1" ]
  }

  run_case prometheus-servicemonitor serviceMonitor
  run_case prometheus-prometheusrules prometheusRules
}

@test "global/extraLabels: serverTelemetry default selector is preserved" {
  cd `chart_dir`
  local output=$(helm template vault . \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --show-only templates/prometheus-servicemonitor.yaml)

  [ "$(echo "$output" | yq -r '.metadata.labels.release')" = "prometheus" ]
}

@test "global/extraLabels: app.kubernetes.io/version is a valid label value" {
  cd `chart_dir`
  local output=$(helm template vault . --show-only templates/server-service.yaml)
  local version=$(echo "$output" | yq -r '.metadata.labels["app.kubernetes.io/version"]')

  # Label values allow alphanumerics, '-', '_' and '.', and are at most 63 chars.
  [[ "$version" =~ ^[A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?$ ]]
  [ "${#version}" -le 63 ]
}

@test "global/extraLabels: fails when overriding a chart-managed label" {
  cd `chart_dir`
  run helm template vault . --set 'global.extraLabels.component=hacked'
  [ "$status" -eq 1 ]
  [[ "$output" =~ "is managed by the chart and cannot be overridden" ]]

  run helm template vault . --set 'global.extraLabels.app\.kubernetes\.io/name=hacked'
  [ "$status" -eq 1 ]
  [[ "$output" =~ "is managed by the chart and cannot be overridden" ]]
}

@test "global/extraLabels: ordinary per-resource labels are still accepted" {
  cd `chart_dir`
  local output=$(helm template vault . \
      --set 'server.extraLabels.foo=bar' \
      --show-only templates/server-statefulset.yaml)

  [ "$(echo "$output" | yq -r '.metadata.labels.foo')" = "bar" ]
  [ "$(echo "$output" | yq -r '.spec.template.metadata.labels.foo')" = "bar" ]
  # The selector labels are untouched.
  [ "$(echo "$output" | yq -r '.spec.template.metadata.labels.component')" = "server" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels.component')" = "server" ]
}

@test "global/extraLabels: app.kubernetes.io/version is set on every resource" {
  cd `chart_dir`
  local output=$(render_every_template)

  local missing=$(echo "$output" | \
      yq -r 'select(.kind != null) | select(.metadata.labels["app.kubernetes.io/version"] == null) | .kind + "/" + .metadata.name')
  [ "${missing}" = "" ]
}

@test "global/extraLabels: app.kubernetes.io/version can be overridden" {
  cd `chart_dir`
  local output=$(helm template vault . \
      --set 'global.extraLabels.app\.kubernetes\.io/version=9.9.9' \
      --show-only templates/server-service.yaml)

  [ "$(echo "$output" | yq -r '.metadata.labels["app.kubernetes.io/version"]')" = "9.9.9" ]
}

@test "global/extraLabels: helm.sh/chart is set on every resource" {
  cd `chart_dir`
  local output=$(render_every_template)

  local missing=$(echo "$output" | \
      yq -r 'select(.kind != null) | select(.metadata.labels["helm.sh/chart"] == null) | .kind + "/" + .metadata.name')
  [ "${missing}" = "" ]
}

@test "global/extraLabels: chart version label kept out of injector and csi pod templates" {
  cd `chart_dir`
  # A single render, so each workload kind appears exactly once.
  local output=$(render_all)

  # The server pod template already carried helm.sh/chart, so it keeps it. The
  # injector and CSI pod templates must not gain it, otherwise every chart
  # release would roll those pods.
  [ "$(echo "$output" | yq -r 'select(.kind == "StatefulSet") | .spec.template.metadata.labels["helm.sh/chart"] // "absent"')" != "absent" ]
  [ "$(echo "$output" | yq -r 'select(.kind == "Deployment") | .spec.template.metadata.labels["helm.sh/chart"] // "absent"')" = "absent" ]
  [ "$(echo "$output" | yq -r 'select(.kind == "DaemonSet") | .spec.template.metadata.labels["helm.sh/chart"] // "absent"')" = "absent" ]

  # All three still get the app version.
  local missing=$(echo "$output" | \
      yq -r 'select(.spec.template.metadata != null) | select(.spec.template.metadata.labels["app.kubernetes.io/version"] == null) | .kind')
  [ "${missing}" = "" ]
}
