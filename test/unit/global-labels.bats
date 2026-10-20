#!/usr/bin/env bats

load _helpers

# The value overrides used by the helpers below are chosen so that, between
# the three modes rendered (standalone with every optional component enabled,
# HA with raft, and OpenShift), every template in the chart renders at least
# one resource. If a resource is missing the expected label, the `unique`
# filter returns more than one element and the assertion fails.

# Renders the chart in standalone mode with every optional component enabled.
_template_standalone() {
  helm template \
      --set 'csi.enabled=true' \
      --set 'ui.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'injector.replicas=2' \
      --set 'injector.podDisruptionBudget.maxUnavailable=1' \
      --set 'server.ingress.enabled=true' \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.networkPolicy.enabled=true' \
      --set 'server.serviceAccount.createSecret=true' \
      --set 'serverTelemetry.serviceMonitor.enabled=true' \
      --set 'serverTelemetry.prometheusRules.enabled=true' \
      --set 'serverTelemetry.prometheusRules.rules[0].alert=test' \
      "$@" \
      .
}

# Renders the chart in HA mode with raft storage.
_template_ha() {
  helm template \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      "$@" \
      .
}

# Renders the chart with the OpenShift specific resources enabled.
_template_openshift() {
  helm template \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.serviceCA.enabled=true' \
      "$@" \
      .
}

#--------------------------------------------------------------------
# global.extraLabels

@test "global/extraLabels: added to all resources in standalone mode" {
  cd `chart_dir`
  local actual=$(_template_standalone --set 'global.extraLabels.foo=bar' |
      yq -s -r 'map(.metadata.labels.foo) | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "global/extraLabels: added to all resources in ha mode" {
  cd `chart_dir`
  local actual=$(_template_ha --set 'global.extraLabels.foo=bar' |
      yq -s -r 'map(.metadata.labels.foo) | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "global/extraLabels: added to all resources on OpenShift" {
  cd `chart_dir`
  local actual=$(_template_openshift --set 'global.extraLabels.foo=bar' |
      yq -s -r 'map(.metadata.labels.foo) | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "global/extraLabels: added to workload pod templates" {
  cd `chart_dir`
  local output=$(_template_standalone --set 'global.extraLabels.foo=bar' |
      yq -s 'map(select(.kind == "StatefulSet" or .kind == "Deployment" or .kind == "DaemonSet"))' | tee /dev/stderr)
  [ "$(echo "$output" | yq -r 'length')" = "3" ]
  [ "$(echo "$output" | yq -r 'map(.spec.template.metadata.labels.foo) | unique | join(",")')" = "bar" ]
}

@test "global/extraLabels: not added to selectors or volumeClaimTemplates" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.auditStorage.enabled=true' \
      --set 'global.extraLabels.foo=bar' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels.foo')" = "null" ]
  [ "$(echo "$output" | yq -r '[.spec.volumeClaimTemplates[].metadata.labels.foo] | unique | join(",")')" = "" ]
}

@test "global/extraLabels: default is empty" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.labels | length' | tee /dev/stderr)
  [ "${actual}" = "5" ]
}

@test "global/extraLabels: reserved chart-managed labels are rejected" {
  cd `chart_dir`
  for key in 'app\.kubernetes\.io/name' 'app\.kubernetes\.io/instance' 'app\.kubernetes\.io/managed-by' 'helm\.sh/chart' 'component' 'vault-active' 'vault-internal'; do
    run helm template \
        --set-string "global.extraLabels.${key}=custom" \
        .
    [ "$status" -eq 1 ]
    echo "$output" | grep 'global.extraLabels must not set'
  done
}

@test "global/extraLabels: values are coerced to strings" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/server-service.yaml \
      --set 'global.extraLabels.numeric=123' \
      --set 'global.extraLabels.boolean=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq '.metadata.labels.numeric')" = '"123"' ]
  [ "$(echo "$output" | yq '.metadata.labels.boolean')" = '"true"' ]
}

@test "global/extraLabels: composes with resource-specific extraLabels" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'global.extraLabels.foo=bar' \
      --set 'server.extraLabels.baz=qux' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.metadata.labels.foo')" = "bar" ]
  [ "$(echo "$output" | yq -r '.spec.template.metadata.labels.baz')" = "qux" ]
}

@test "global/extraLabels: resource-specific extraLabels take precedence" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'global.extraLabels.foo=global' \
      --set 'server.extraLabels.foo=server' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "server" ]
}

#--------------------------------------------------------------------
# app.kubernetes.io/version

@test "global/versionLabel: set from chart appVersion on all resources" {
  cd `chart_dir`
  local appVersion=$(yq -r '.appVersion' Chart.yaml)

  local actual=$(_template_standalone |
      yq -s -r 'map(.metadata.labels."app.kubernetes.io/version") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${appVersion}" ]

  actual=$(_template_ha |
      yq -s -r 'map(.metadata.labels."app.kubernetes.io/version") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${appVersion}" ]

  actual=$(_template_openshift |
      yq -s -r 'map(.metadata.labels."app.kubernetes.io/version") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${appVersion}" ]
}

@test "global/versionLabel: set on workload pod templates" {
  cd `chart_dir`
  local appVersion=$(yq -r '.appVersion' Chart.yaml)
  local actual=$(_template_standalone |
      yq -s -r 'map(select(.kind == "StatefulSet" or .kind == "Deployment" or .kind == "DaemonSet") | .spec.template.metadata.labels."app.kubernetes.io/version") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${appVersion}" ]
}

@test "global/versionLabel: overridable via global.extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set-string 'global.extraLabels.app\.kubernetes\.io/version=overridden' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels."app.kubernetes.io/version"' | tee /dev/stderr)
  [ "${actual}" = "overridden" ]
}

#--------------------------------------------------------------------
# helm.sh/chart

@test "global/chartLabel: set on all resources" {
  cd `chart_dir`
  local chart=$(yq -r '"\(.name)-\(.version)"' Chart.yaml)

  local actual=$(_template_standalone |
      yq -s -r 'map(.metadata.labels."helm.sh/chart") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${chart}" ]

  actual=$(_template_ha |
      yq -s -r 'map(.metadata.labels."helm.sh/chart") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${chart}" ]

  actual=$(_template_openshift |
      yq -s -r 'map(.metadata.labels."helm.sh/chart") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${chart}" ]
}

@test "global/chartLabel: set on workload pod templates" {
  cd `chart_dir`
  local chart=$(yq -r '"\(.name)-\(.version)"' Chart.yaml)
  local actual=$(_template_standalone |
      yq -s -r 'map(select(.kind == "StatefulSet" or .kind == "Deployment" or .kind == "DaemonSet") | .spec.template.metadata.labels."helm.sh/chart") | unique | join(",")' | tee /dev/stderr)
  [ "${actual}" = "${chart}" ]
}
