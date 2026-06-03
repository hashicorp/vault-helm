#!/usr/bin/env bats

load _helpers

# Verifies the HTTPRoute template is not rendered unless explicitly enabled.
@test "server/httproute: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-httproute.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# Verifies namespace selection and that global.namespace overrides the release namespace.
@test "server/httproute: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.httproute.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.httproute.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

# Verifies HTTPRoute rendering is disabled when injector.externalVaultAddr is configured.
@test "server/httproute: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.httproute.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# Verifies hostnames are rendered and the configured root path (/) match is preserved.
@test "server/httproute: checking host entry gets added and path is /" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.hostnames[0]' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.value' | tee /dev/stderr)
  [ "${actual}" = '/' ]
}

# Verifies custom path match type and value are rendered in rule matches.
@test "server/httproute: checking custom matches path" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.type' | tee /dev/stderr)
  [ "${actual}" = 'PathPrefix' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.value' | tee /dev/stderr)
  [ "${actual}" = '/foo/' ]
}

# Verifies a Vault backendRef is rendered when a route match/path is configured.
@test "server/httproute: vault backend should be added when I specify a path" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].backendRefs[0].name  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}

# Verifies custom labels are added to HTTPRoute metadata.
@test "server/httproute: labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.labels.traffic=external' \
      --set 'server.httproute.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

# Verifies annotations supplied as a string are parsed into metadata.annotations.
@test "server/httproute: annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.annotations=kubernetes.io/httproute.class: nginx' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/httproute.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

# Verifies annotations with escaped dotted keys are rendered correctly.
@test "server/httproute: annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set server.httproute.annotations."kubernetes\.io/httproute\.class"=nginx \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/httproute.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

# Verifies configured parentRefs are rendered in spec.parentRefs.
@test "server/httproute: parentRefs added to object spec" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set server.httproute.parentRefs[0].name=test-gateway \
      --set server.httproute.parentRefs[0].namespace=test-ns \
      . | tee /dev/stderr |
      yq -r '.spec.parentRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "test-gateway" ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set server.httproute.parentRefs[0].name=test-gateway \
      --set server.httproute.parentRefs[0].namespace=test-ns \
      . | tee /dev/stderr |
      yq -r '.spec.parentRefs[0].namespace' | tee /dev/stderr)
  [ "${actual}" = "test-ns" ]  
}

# Verifies parentRefs are omitted when not explicitly configured.
@test "server/httproute: parentRefs not added by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.parentRefs[0]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}


# Verifies HA mode defaults backendRef service selection to the active service.
@test "server/httproute: uses active service when ha by default - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-active" ]
}

# Verifies HA mode can be configured to use the regular service instead of active.
@test "server/httproute: uses regular service when configured with ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.activeService=false' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Verifies non-HA mode uses the regular Vault service backend.
@test "server/httproute: uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Verifies backend service reference formatting remains correct on Kubernetes 1.26.3.
@test "server/httproute: k8s 1.26.3 uses correct service format when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      --kube-version 1.26.3 \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Verifies activeService does not alter backend selection when HA is disabled.
@test "server/httproute: uses regular service when not ha and activeService is true - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.activeService=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Verifies custom rule filters are rendered, including header name and value.
@test "server/httproute: checking custom filters" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].type' | tee /dev/stderr)
  [ "${actual}" = 'RequestHeaderModifier' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].requestHeaderModifier.set[0].name' | tee /dev/stderr)
  [ "${actual}" = 'test-header-name' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].requestHeaderModifier.set[0].value' | tee /dev/stderr)
  [ "${actual}" = 'new-test-header-value' ]
}

# Verifies filters are omitted when not configured.
@test "server/httproute: filters not added by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].filters[0]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

# Verifies fully customized additionalRules are rendered with filters and path matches.
@test "server/httproute: checking fullyCustomizedRule" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.additionalRules[0].filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      --set 'server.httproute.additionalRules[0].matches[0].path.type=PathPrefix' \
      --set 'server.httproute.additionalRules[0].matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].type' | tee /dev/stderr)
  [ "${actual}" = 'RequestHeaderModifier' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.additionalRules[0].filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      --set 'server.httproute.additionalRules[0].matches[0].path.type=PathPrefix' \
      --set 'server.httproute.additionalRules[0].matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].requestHeaderModifier.set[0].name' | tee /dev/stderr)
  [ "${actual}" = 'test-header-name' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.additionalRules[0].filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      --set 'server.httproute.additionalRules[0].matches[0].path.type=PathPrefix' \
      --set 'server.httproute.additionalRules[0].matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].requestHeaderModifier.set[0].value' | tee /dev/stderr)
  [ "${actual}" = 'new-test-header-value' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.additionalRules[0].filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      --set 'server.httproute.additionalRules[0].matches[0].path.type=PathPrefix' \
      --set 'server.httproute.additionalRules[0].matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.type' | tee /dev/stderr)
  [ "${actual}" = 'PathPrefix' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.additionalRules[0].filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      --set 'server.httproute.additionalRules[0].matches[0].path.type=PathPrefix' \
      --set 'server.httproute.additionalRules[0].matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.value' | tee /dev/stderr)
  [ "${actual}" = '/foo/' ]
}

# Verifies no additionalRules are rendered by default.
@test "server/httproute: additionalRules not added by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[1]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}
