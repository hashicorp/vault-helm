#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# extraObjects

@test "extraObjects: not rendered by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/extra-objects.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "extraObjects: renders an object given as a map" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -r '.metadata.name' | tee /dev/stderr
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: from-a-map
    data:
      key: value
EOF
)
  [ "${actual}" = "from-a-map" ]
}

@test "extraObjects: renders an object given as a string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -r '.data.key' | tee /dev/stderr
extraObjects:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: from-a-string
    data:
      key: value
EOF
)
  [ "${actual}" = "value" ]
}

@test "extraObjects: renders every object in the list" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -s -r 'map(.metadata.name) | join(",")' | tee /dev/stderr
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: first
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: second
EOF
)
  [ "${actual}" = "first,second" ]
}

@test "extraObjects: accepts a map of objects" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -s -r 'map(.metadata.name) | sort | join(",")' | tee /dev/stderr
extraObjects:
  alpha:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: first
  beta: |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: second
EOF
)
  [ "${actual}" = "first,second" ]
}

@test "extraObjects: objects are templated against the chart context" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      --namespace vault-namespace \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -r '[.metadata.name, .metadata.namespace, .metadata.labels["app.kubernetes.io/name"]] | join(",")' | tee /dev/stderr
extraObjects:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ include "vault.fullname" . }}-extra
      namespace: {{ include "vault.namespace" . }}
      labels:
        app.kubernetes.io/name: {{ include "vault.name" . }}
    data:
      chart: {{ .Chart.Name }}
EOF
)
  [ "${actual}" = "release-name-vault-extra,vault-namespace,vault" ]
}

@test "extraObjects: templated values are resolved in the map form too" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -r '.metadata.name' | tee /dev/stderr
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: '{{ include "vault.fullname" . }}-extra'
EOF
)
  [ "${actual}" = "release-name-vault-extra" ]
}

@test "extraObjects: rendered when global.enabled is false" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      --set 'global.enabled=false' \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -r '.metadata.name' | tee /dev/stderr
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: still-here
EOF
)
  [ "${actual}" = "still-here" ]
}

@test "extraObjects: an entry that renders to nothing is skipped" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      --set 'csi.enabled=false' \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -s -r 'map(.metadata.name) | join(",")' | tee /dev/stderr
extraObjects:
  server: |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: always-here
  csi: |
    {{- if .Values.csi.enabled }}
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: only-with-csi
    {{- end }}
EOF
)
  [ "${actual}" = "always-here" ]
}

@test "extraObjects: objects for the server and the CSI provider can be deployed together" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/extra-objects.yaml \
      --set 'csi.enabled=true' \
      . \
      -f - <<EOF \
      | tee /dev/stderr \
      | yq -s -r 'map(.metadata.name) | sort | join(",")' | tee /dev/stderr
extraObjects:
  server: |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ include "vault.fullname" . }}-server-tls
  csi: |
    {{- if .Values.csi.enabled }}
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ include "vault.fullname" . }}-csi-tls
    {{- end }}
EOF
)
  [ "${actual}" = "release-name-vault-csi-tls,release-name-vault-server-tls" ]
}

@test "extraObjects: an entry that is neither a map nor a string fails" {
  cd `chart_dir`
  run helm template \
      --show-only templates/extra-objects.yaml \
      --set 'extraObjects[0]=42' \
      .
  [ "$status" -eq 1 ]
  [[ "$output" =~ "extraObjects[0]: expected a map or a string" ]]
}

@test "extraObjects: a failing entry in the map form is named by its key" {
  cd `chart_dir`
  run helm template \
      --show-only templates/extra-objects.yaml \
      --set 'extraObjects.serverCert=42' \
      .
  [ "$status" -eq 1 ]
  [[ "$output" =~ "extraObjects[serverCert]: expected a map or a string" ]]
}
