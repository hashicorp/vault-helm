#!/usr/bin/env bats

load _helpers

@test "server/ConfigMap: enabled by default" {
  cd `chart_dir`
  local actual
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ConfigMap: raft config disabled by default" {
  cd `chart_dir`
  local actual
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      grep "raft" | yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" != "true" ]
}

@test "server/ConfigMap: raft config can be enabled" {
  cd `chart_dir`
  local actual
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      . | tee /dev/stderr |
      grep "raft" | yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ConfigMap: raft config templated not JSON" {
  cd `chart_dir`
  local actual
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set "server.ha.raft.config=hello = {{ .Chart.Name }}" \
      . | tee /dev/stderr |
      yq '.data' | tee /dev/stderr)
  local check=$(echo "${actual}" | \
    yq '."extraconfig-from-values.hcl" == "hello = vault\ndisable_mlock = true"')
  [ "${check}" = "true" ]
}

@test "server/ConfigMap: raft config templated JSON" {
  cd `chart_dir`
  local actual
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set "server.ha.raft.config=\{\"hello\": \"{{ .Chart.Name }}\"\}" \
      . | tee /dev/stderr |
      yq '.data' | tee /dev/stderr)
  local check=$(echo "${actual}" | \
    yq '."extraconfig-from-values.hcl" == "{\"disable_mlock\":true,\"hello\":\"vault\"}"')
  [ "${check}" = "true" ]
}

@test "server/ConfigMap: disabled by server.dev.enabled true" {
  cd `chart_dir`
  local actual
  actual=$( (helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ConfigMap: disable with global.enabled" {
  cd `chart_dir`
  local actual
  actual=$( (helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ConfigMap: namespace" {
  cd `chart_dir`
  local actual
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/ConfigMap: standalone extraConfig is set as JSON" {
  cd `chart_dir`
  local data
  data=$(helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.standalone.config=\{\"hello\": \"world\"\}' \
      . | tee /dev/stderr |
      yq '.data')
  local checkLength=$(echo "${data}" | yq '(. | length) == 1')
  [ "${checkLength}" = "true" ]
  local checkExtraConfig=$(echo "${data}" | \
    yq '."extraconfig-from-values.hcl" == "{\"disable_mlock\":true,\"hello\":\"world\"}"')
  [ "${checkExtraConfig}" = 'true' ]

  data=$(helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.standalone.config=\{\"foo\": \"bar\"\}' \
      . | tee /dev/stderr |
      yq '.data' | tee /dev/stderr)
  checkLength=$(echo "${data}" | yq '(. | length) == 1')
  [ "${checkLength}" = "true" ]
  checkExtraConfig=$(echo "${data}" | \
    yq '."extraconfig-from-values.hcl" == "{\"disable_mlock\":true,\"foo\":\"bar\"}"')
  [ "${checkExtraConfig}" = 'true' ]

  data=$(helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.standalone.config=\{\"disable_mlock\": false\,\"foo\":\"bar\"\}' \
      . | tee /dev/stderr |
      yq '.data' | tee /dev/stderr)
  checkLength=$(echo "${data}" | yq '(. | length) == 1')
  [ "${checkLength}" = "true" ]
  checkExtraConfig=$(echo "${data}" | \
    yq '."extraconfig-from-values.hcl" == "{\"disable_mlock\":false,\"foo\":\"bar\"}"')
  [ "${checkExtraConfig}" = 'true' ]
}

@test "server/ConfigMap: standalone extraConfig is set as not JSON" {
  cd `chart_dir`
  local data
  data=$(helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.standalone.config=baz = false' \
      . | tee /dev/stderr |
      yq '.data')
  [ "$(echo "${data}" | \
    yq '(. | length) == 1')" = "true" ]
  [ "$(echo "${data}" | \
    yq '."extraconfig-from-values.hcl" == "baz = false\ndisable_mlock = true"')" = 'true' ]
}

@test "server/ConfigMap: standalone structured extraConfig fails" {
  cd "$(chart_dir)"
  local ret
  ret=0
  local output
  output="$(helm template \
        --show-only templates/server-config-configmap.yaml  \
        --set 'server.standalone.enabled=true' \
        --set 'server.standalone.config.key1=value1' \
        . 2>&1)" || ret=$?
  [ "${ret}" -ne 0 ]
  echo "${output}" | grep -q "structured server config is not supported, value must be a string"
}

@test "server/ConfigMap: ha extraConfig is set as JSON" {
  cd `chart_dir`
  local data
  data=$(helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.config=\{\"hello\": \"ha-world\"\}' \
      . | tee /dev/stderr |
      yq '.data' | tee /dev/stderr)
  local checkLength=$(echo "${data}" | yq '(. | length) == 1')
  [ "${checkLength}" = "true" ]
  local checkExtraConfig=$(echo "${data}" | \
    yq '."extraconfig-from-values.hcl" == "{\"disable_mlock\":true,\"hello\":\"ha-world\"}"')
  [ "$checkExtraConfig" = 'true' ]

 data=$(helm template \
      --show-only templates/server-config-configmap.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.config=\{\"foo\": \"bar\"\,\"disable_mlock\":false\}' \
      . | tee /dev/stderr |
      yq '.data' | tee /dev/stderr)
  checkLength=$(echo "${data}" | yq '(. | length) == 1')
  [ "$checkLength" = "true" ]
  checkExtraConfig=$(echo "${data}" | \
    yq '."extraconfig-from-values.hcl" == "{\"disable_mlock\":false,\"foo\":\"bar\"}"')
  [ "${checkExtraConfig}" = 'true' ]
}

@test "server/ConfigMap: disabled by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ConfigMap: config checksum annotation defaults to off" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      . | tee /dev/stderr |
      yq '.metadata.annotations["vault.hashicorp.com/config-checksum"] == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ConfigMap: config checksum annotation can be enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-config-configmap.yaml \
      --set 'server.includeConfigAnnotation=true' \
      . | tee /dev/stderr |
      yq '.metadata.annotations["vault.hashicorp.com/config-checksum"] == null' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
