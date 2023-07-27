#!/usr/bin/env bats

load _helpers

@test "injector/MutatingWebhookConfiguration: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/MutatingWebhookConfiguration: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/MutatingWebhookConfiguration: disable with injector.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/MutatingWebhookConfiguration: namespace is set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].clientConfig.service.namespace' | tee /dev/stderr)
  [ "${actual}" = "\"foo\"" ]
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].clientConfig.service.namespace' | tee /dev/stderr)
  [ "${actual}" = "\"bar\"" ]
}

@test "injector/MutatingWebhookConfiguration: caBundle is empty string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].clientConfig.caBundle' | tee /dev/stderr)
  [ "${actual}" = "\"\"" ]
}

@test "injector/MutatingWebhookConfiguration: failurePolicy 'Ignore' by default (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].failurePolicy' | tee /dev/stderr)
  [ "${actual}" = "\"Ignore\"" ]
}

@test "injector/MutatingWebhookConfiguration: can set failurePolicy (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --set 'injector.failurePolicy=Fail' \
      . | tee /dev/stderr |
      yq '.webhooks[0].failurePolicy' | tee /dev/stderr)

  [ "${actual}" = "\"Fail\"" ]
}

@test "injector/MutatingWebhookConfiguration: webhook.failurePolicy 'Ignore' by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.failurePolicy=Invalid' \
      . | tee /dev/stderr |
      yq '.webhooks[0].failurePolicy' | tee /dev/stderr)

  [ "${actual}" = "\"Ignore\"" ]
}

@test "injector/MutatingWebhookConfiguration: can set webhook.failurePolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.failurePolicy=Fail' \
      --set 'injector.failurePolicy=Invalid' \
      . | tee /dev/stderr |
      yq '.webhooks[0].failurePolicy' | tee /dev/stderr)

  [ "${actual}" = "\"Fail\"" ]
}

@test "injector/MutatingWebhookConfiguration: webhook.matchPolicy 'Exact' by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      . | tee /dev/stderr |
      yq '.webhooks[0].matchPolicy' | tee /dev/stderr)

  [ "${actual}" = "\"Exact\"" ]
}

@test "injector/MutatingWebhookConfiguration: can set webhook.matchPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.matchPolicy=Equivalent' \
      . | tee /dev/stderr |
      yq '.webhooks[0].matchPolicy' | tee /dev/stderr)

  [ "${actual}" = "\"Equivalent\"" ]
}

@test "injector/MutatingWebhookConfiguration: timeoutSeconds by default 30" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      . | tee /dev/stderr |
      yq '.webhooks[0].timeoutSeconds' | tee /dev/stderr)

  [ "${actual}" = "30" ]
}

@test "injector/MutatingWebhookConfiguration: can set webhook.timeoutSeconds" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.timeoutSeconds=50' \
      . | tee /dev/stderr |
      yq '.webhooks[0].timeoutSeconds' | tee /dev/stderr)

  [ "${actual}" = "50" ]
}

#--------------------------------------------------------------------
# annotations

@test "injector/MutatingWebhookConfiguration: default webhookAnnotations (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/MutatingWebhookConfiguration: specify webhookAnnotations yaml (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --set 'injector.webhookAnnotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "injector/MutatingWebhookConfiguration: specify webhookAnnotations yaml string (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --set 'injector.webhookAnnotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "injector/MutatingWebhookConfiguration: default webhook.annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml \
      --set 'injector.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/MutatingWebhookConfiguration: specify webhook.annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.annotations.foo=bar' \
      --set 'injector.webhookAnnotations.invalid=invalid' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "injector/MutatingWebhookConfiguration: specify webhook.annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.annotations=foo: bar' \
      --set 'injector.webhookAnnotations=invalid: invalid' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# namespaceSelector

@test "injector/MutatingWebhookConfiguration: namespaceSelector empty by default (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].namespaceSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/MutatingWebhookConfiguration: can set namespaceSelector (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.namespaceSelector.matchLabels.injector=true' \
      . | tee /dev/stderr |
      yq '.webhooks[0].namespaceSelector.matchLabels.injector' | tee /dev/stderr)

  [ "${actual}" = "true" ]
}

@test "injector/MutatingWebhookConfiguration: webhook.namespaceSelector empty by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].namespaceSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/MutatingWebhookConfiguration: can set set webhook.namespaceSelector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.namespaceSelector.matchLabels.injector=true' \
      --set 'injector.namespaceSelector.matchLabels.injector=false' \
      . | tee /dev/stderr |
      yq '.webhooks[0].namespaceSelector.matchLabels.injector' | tee /dev/stderr)

  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# objectSelector

@test "injector/MutatingWebhookConfiguration: objectSelector empty by default (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --namespace foo \
      . | tee /dev/stderr |
      yq '.webhooks[0].objectSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/MutatingWebhookConfiguration: can set objectSelector (deprecated)" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook=null' \
      --set 'injector.objectSelector.matchLabels.injector=true' \
      . | tee /dev/stderr |
      yq '.webhooks[0].objectSelector.matchLabels.injector' | tee /dev/stderr)

  [ "${actual}" = "true" ]
}

@test "injector/MutatingWebhookConfiguration: webhook.objectSelector not empty by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.webhooks[0].objectSelector.matchExpressions[0].key' | tee /dev/stderr)
  [ "${actual}" = "app.kubernetes.io/name" ]
}

@test "injector/MutatingWebhookConfiguration: can set webhook.objectSelector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-mutating-webhook.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.webhook.objectSelector.matchLabels.injector=true' \
      --set 'injector.objectSelector.matchLabels.injector=false' \
      . | tee /dev/stderr |
      yq '.webhooks[0].objectSelector.matchLabels.injector' | tee /dev/stderr)

  [ "${actual}" = "true" ]
}