#!/usr/bin/env bats
#
# Tests for templates/server-httproute.yaml
#
# Covers the HTTPRoute Gateway API resource that exposes the Vault server.
# Tests verify: enable/disable conditions (default off, externalVaultAddr),
# metadata (namespace, labels, annotations), spec fields (parentRefs required,
# hostnames, matches, filters, additionalRules), and backend service selection
# logic (plain service vs. HA active service based on mode and activeService flag).

load _helpers

# HTTPRoute resource is not rendered unless explicitly enabled via server.httproute.enabled=true.
@test "server/httproute: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-httproute.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# global.namespace overrides the helm release namespace when set.
@test "server/httproute: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

# HTTPRoute is suppressed when injector.externalVaultAddr is set because the server is external.
@test "server/httproute: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-httproute.yaml  \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# Provided hostname appears in spec.hostnames and the path value is propagated to spec.rules[0].matches[0].
@test "server/httproute: checking host entry gets added and path is /" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.hostnames[0]' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.value' | tee /dev/stderr)
  [ "${actual}" = '/' ]
}

# Custom matches (type and value) are passed through to spec.rules[0].matches unchanged.
@test "server/httproute: checking custom matches path" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.type' | tee /dev/stderr)
  [ "${actual}" = 'PathPrefix' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.value' | tee /dev/stderr)
  [ "${actual}" = '/foo/' ]
}

# spec.rules[0].backendRefs[0].name is always populated (non-empty) when the route is rendered.
@test "server/httproute: vault backend should be added when I specify a path" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.hostnames[0]=test.com' \
      --set 'server.httproute.matches[0].path.type=PathPrefix' \
      --set 'server.httproute.matches[0].path.value=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].backendRefs[0].name  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}

# Custom labels from server.httproute.labels are merged into metadata.labels.
@test "server/httproute: labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.labels.traffic=external' \
      --set 'server.httproute.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

# Annotations provided as a plain string (key: value) are added to metadata.annotations.
@test "server/httproute: annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.annotations=kubernetes.io/httproute.class: nginx' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/httproute.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

# Annotations with dots in the key (escaped in --set) are correctly preserved in metadata.annotations.
@test "server/httproute: annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set server.httproute.annotations."kubernetes\.io/httproute\.class"=nginx \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/httproute.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

# parentRefs entries (name and namespace) are passed through to spec.parentRefs unchanged.
@test "server/httproute: parentRefs added to object spec" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.parentRefs[0].namespace=test-ns' \
      . | tee /dev/stderr |
      yq -r '.spec.parentRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "test-gateway" ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.parentRefs[0].namespace=test-ns' \
      . | tee /dev/stderr |
      yq -r '.spec.parentRefs[0].namespace' | tee /dev/stderr)
  [ "${actual}" = "test-ns" ]
}


# In HA mode the backendRef defaults to the "-active" service to route only to the active node.
@test "server/httproute: uses active service when ha by default - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-active" ]
}

# activeService=false in HA mode falls back to the plain service instead of the "-active" one.
@test "server/httproute: uses regular service when configured with ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.activeService=false' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Non-HA mode always uses the plain service regardless of activeService setting.
@test "server/httproute: uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Verify backendRef service name is correct on Kubernetes 1.26.3 (older kube-version flag).
@test "server/httproute: k8s 1.26.3 uses correct service format when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      --kube-version 1.26.3 \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# activeService=true is a no-op in non-HA mode; the plain service is still used.
@test "server/httproute: uses regular service when not ha and activeService is true - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.activeService=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].backendRefs[0].name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

# Filters from server.httproute.filters are placed in spec.rules[0].filters with all nested fields intact.
@test "server/httproute: checking custom filters" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].type' | tee /dev/stderr)
  [ "${actual}" = 'RequestHeaderModifier' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].requestHeaderModifier.set[0].name' | tee /dev/stderr)
  [ "${actual}" = 'test-header-name' ]

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].filters[0].requestHeaderModifier.set[0].value' | tee /dev/stderr)
  [ "${actual}" = 'new-test-header-value' ]
}

# spec.rules[0].filters is absent (null) when no filters are configured.
@test "server/httproute: filters not added by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].filters[0]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

# additionalRules entries are prepended to spec.rules and support full filter+match customisation.
@test "server/httproute: checking fullyCustomizedRule" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
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
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
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
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
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
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
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
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      --set 'server.httproute.additionalRules[0].filters[0].type=RequestHeaderModifier' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].name=test-header-name' \
      --set 'server.httproute.additionalRules[0].filters[0].requestHeaderModifier.set[0].value=new-test-header-value' \
      --set 'server.httproute.additionalRules[0].matches[0].path.type=PathPrefix' \
      --set 'server.httproute.additionalRules[0].matches[0].path.value=/foo/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].matches[0].path.value' | tee /dev/stderr)
  [ "${actual}" = '/foo/' ]
}

# spec.rules[1] is absent (null) when no additionalRules are configured; only the default rule exists.
@test "server/httproute: additionalRules not added by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-httproute.yaml \
      --set 'server.httproute.enabled=true' \
      --set 'server.httproute.parentRefs[0].name=test-gateway' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[1]' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}
