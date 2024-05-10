#!/usr/bin/env bats

load _helpers

@test "injector/deployment: default injector.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: enable with injector.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/deployment: enable with injector.enabled true and global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "injector/deployment: image defaults to injector.image" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.image.repository=foo' \
      --set 'injector.image.tag=1.2.3' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.image.repository=foo' \
      --set 'injector.image.tag=1.2.3' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]
}

@test "injector/deployment: default imagePullPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "IfNotPresent" ]
}

@test "injector/deployment: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/deployment: custom resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.resources.requests.memory=256Mi' \
      --set 'injector.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.resources.limits.memory=256Mi' \
      --set 'injector.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]
}

@test "injector/deployment: enable metrics" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.metrics.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[9].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_TELEMETRY_PATH" ]

  local actual=$(echo $object |
      yq -r '.[9].value' | tee /dev/stderr)
  [ "${actual}" = "/metrics" ]
}

@test "injector/deployment: manual TLS environment vars" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.certs.secretName=foobar' \
      --set 'injector.certs.certName=test.crt' \
      --set 'injector.certs.keyName=test.key' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TLS_CERT_FILE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "/etc/webhook/certs/test.crt" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TLS_KEY_FILE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "/etc/webhook/certs/test.key" ]
}

@test "injector/deployment: auto TLS by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TLS_AUTO")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "release-name-vault-agent-injector-cfg" ]

  # helm template does uses current context namespace and ignores namespace flags, so
  # discover the targeted namespace so we can check the rendered value correctly.
  local namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TLS_AUTO_HOSTS")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "release-name-vault-agent-injector-svc,release-name-vault-agent-injector-svc.${namespace:-default},release-name-vault-agent-injector-svc.${namespace:-default}.svc" ]
}

@test "injector/deployment: manual TLS adds volume mount" {
   cd `chart_dir`
   local object=$(helm template \
       --show-only templates/injector-deployment.yaml  \
       --set 'injector.enabled=true' \
       --set 'injector.certs.secretName=vault-tls' \
       . | tee /dev/stderr |
       yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "webhook-certs")' | tee /dev/stderr)

   local actual=$(echo $object |
       yq -r '.mountPath' | tee /dev/stderr)
   [ "${actual}" = "/etc/webhook/certs" ]

   local actual=$(echo $object |
       yq -r '.readOnly' | tee /dev/stderr)
   [ "${actual}" = "true" ]
}

@test "injector/deployment: with externalVaultAddr" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://vault-outside" ]
}

@test "injector/deployment: with global.externalVaultAddr" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'global.externalVaultAddr=http://vault-outside' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://vault-outside" ]
}

@test "injector/deployment: global.externalVaultAddr takes precendence over injector.externalVaultAddr" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'global.externalVaultAddr=http://global-vault-outside' \
      --set 'injector.externalVaultAddr=http://injector-vault-outside' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://global-vault-outside" ]
}

@test "injector/deployment: without externalVaultAddr" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --release-name not-external-test  \
      --namespace default \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://not-external-test-vault.default.svc:8200" ]
}

@test "injector/deployment: default authPath" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_VAULT_AUTH_PATH")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "auth/kubernetes" ]
}

@test "injector/deployment: custom authPath" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.authPath=auth/k8s' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_VAULT_AUTH_PATH")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "auth/k8s" ]
}

@test "injector/deployment: default livenessProbe settings" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)

  local actual=$(echo "$object" | yq '.failureThreshold' | tee /dev/stderr)
    [ "${actual}" = "2" ]
  local actual=$(echo "$object" | yq '.initialDelaySeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
  local actual=$(echo "$object" | yq '.periodSeconds' | tee /dev/stderr)
    [ "${actual}" = "2" ]
  local actual=$(echo "$object" | yq '.successThreshold' | tee /dev/stderr)
    [ "${actual}" = "1" ]
  local actual=$(echo "$object" | yq '.timeoutSeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
}

@test "injector/deployment: can set livenessProbe settings" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.livenessProbe.failureThreshold=100' \
      --set 'injector.livenessProbe.initialDelaySeconds=100' \
      --set 'injector.livenessProbe.periodSeconds=100' \
      --set 'injector.livenessProbe.successThreshold=100' \
      --set 'injector.livenessProbe.timeoutSeconds=100' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)

  local actual=$(echo "$object" | yq '.failureThreshold' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.initialDelaySeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.periodSeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.successThreshold' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.timeoutSeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
}

@test "injector/deployment: default readinessProbe settings" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)

  local actual=$(echo "$object" | yq '.failureThreshold' | tee /dev/stderr)
    [ "${actual}" = "2" ]
  local actual=$(echo "$object" | yq '.initialDelaySeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
  local actual=$(echo "$object" | yq '.periodSeconds' | tee /dev/stderr)
    [ "${actual}" = "2" ]
  local actual=$(echo "$object" | yq '.successThreshold' | tee /dev/stderr)
    [ "${actual}" = "1" ]
  local actual=$(echo "$object" | yq '.timeoutSeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
}

@test "injector/deployment: can set readinessProbe settings" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.readinessProbe.failureThreshold=100' \
      --set 'injector.readinessProbe.initialDelaySeconds=100' \
      --set 'injector.readinessProbe.periodSeconds=100' \
      --set 'injector.readinessProbe.successThreshold=100' \
      --set 'injector.readinessProbe.timeoutSeconds=100' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)

  local actual=$(echo "$object" | yq '.failureThreshold' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.initialDelaySeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.periodSeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.successThreshold' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.timeoutSeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
}

@test "injector/deployment: default startupProbe settings" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].startupProbe' | tee /dev/stderr)

  local actual=$(echo "$object" | yq '.failureThreshold' | tee /dev/stderr)
    [ "${actual}" = "12" ]
  local actual=$(echo "$object" | yq '.initialDelaySeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
  local actual=$(echo "$object" | yq '.periodSeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
  local actual=$(echo "$object" | yq '.successThreshold' | tee /dev/stderr)
    [ "${actual}" = "1" ]
  local actual=$(echo "$object" | yq '.timeoutSeconds' | tee /dev/stderr)
    [ "${actual}" = "5" ]
}

@test "injector/deployment: can set startupProbe settings" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.startupProbe.failureThreshold=100' \
      --set 'injector.startupProbe.initialDelaySeconds=100' \
      --set 'injector.startupProbe.periodSeconds=100' \
      --set 'injector.startupProbe.successThreshold=100' \
      --set 'injector.startupProbe.timeoutSeconds=100' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].startupProbe' | tee /dev/stderr)

  local actual=$(echo "$object" | yq '.failureThreshold' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.initialDelaySeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.periodSeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.successThreshold' | tee /dev/stderr)
    [ "${actual}" = "100" ]
  local actual=$(echo "$object" | yq '.timeoutSeconds' | tee /dev/stderr)
    [ "${actual}" = "100" ]
}

@test "injector/deployment: default logLevel" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_LOG_LEVEL")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "info" ]
}

@test "injector/deployment: custom logLevel" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.logLevel=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_LOG_LEVEL")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "foo" ]
}

@test "injector/deployment: default logFormat" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_LOG_FORMAT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "standard" ]
}

@test "injector/deployment: custom logFormat" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.logFormat=json' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_LOG_FORMAT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "json" ]
}

@test "injector/deployment: default revoke on shutdown" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_REVOKE_ON_SHUTDOWN")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "false" ]
}

@test "injector/deployment: custom revoke on shutdown" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.revokeOnShutdown=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_REVOKE_ON_SHUTDOWN")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "true" ]
}

@test "injector/deployment: disable security context when openshift enabled" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_SET_SECURITY_CONTEXT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "false" ]
}

#--------------------------------------------------------------------
# securityContext for pod and container

# for backward compatibility
@test "injector/deployment: backward pod securityContext" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.uid=200' \
      --set 'injector.gid=4000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext' | tee /dev/stderr)

  local value=$(echo $actual | yq -r .runAsUser | tee /dev/stderr)
  [ "${value}" = "200" ]

  local value=$(echo $actual | yq -r .runAsGroup | tee /dev/stderr)
  [ "${value}" = "4000" ]
}

@test "injector/deployment: default pod securityContext" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext' | tee /dev/stderr)
  [ "${actual}" != "null" ]

  local value=$(echo $actual | yq -r .fsGroup | tee /dev/stderr)
  [ "${value}" = "1000" ]

  local value=$(echo $actual | yq -r .runAsGroup | tee /dev/stderr)
  [ "${value}" = "1000" ]

  local value=$(echo $actual | yq -r .runAsNonRoot | tee /dev/stderr)
  [ "${value}" = "true" ]

  local value=$(echo $actual | yq -r .runAsUser | tee /dev/stderr)
  [ "${value}" = "100" ]
}

@test "injector/deployment: custom pod securityContext" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.securityContext.pod.runAsNonRoot=true' \
      --set 'injector.securityContext.pod.runAsGroup=1001' \
      --set 'injector.securityContext.pod.runAsUser=1001' \
      --set 'injector.securityContext.pod.fsGroup=1000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "1001" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.securityContext.pod.runAsNonRoot=false' \
      --set 'injector.securityContext.pod.runAsGroup=1000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsNonRoot' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.securityContext.pod.runAsUser=1001' \
      --set 'injector.securityContext.pod.fsGroup=1000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "1001" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.securityContext.pod.runAsNonRoot=true' \
      --set 'injector.securityContext.pod.fsGroup=1001' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "1001" ]
}

@test "injector/deployment: custom pod securityContext from string" {
  cd `chart_dir`
  local multi=$(cat <<EOF
foo: bar
bar: foo
EOF
)
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set "injector.securityContext.pod=$multi" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.bar' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

@test "injector/deployment: custom container securityContext" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set "injector.securityContext.container.bar=foo" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.bar' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

@test "injector/deployment: custom container securityContext from string" {
  cd `chart_dir`
  local multi=$(cat <<EOF
foo: bar
bar: foo
EOF
)
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set "injector.securityContext.container=$multi" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.bar' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

@test "injector/deployment: default container securityContext sidecar-injector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext' | tee /dev/stderr)
  [ "${actual}" != "null" ]

  local value=$(echo $actual | yq -r .allowPrivilegeEscalation | tee /dev/stderr)
  [ "${value}" = "false" ]

  local value=$(echo $actual | yq -r .capabilities.drop[0] | tee /dev/stderr)
  [ "${value}" = "ALL" ]
}

@test "injector/deployment: custom container securityContext sidecar-injector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.securityContext.container.privileged=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.privileged' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.securityContext.container.readOnlyRootFilesystem=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# extraEnvironmentVars

@test "injector/deployment: set extraEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.extraEnvironmentVars.FOO=bar' \
      --set 'injector.extraEnvironmentVars.FOOBAR=foobar' \
      --set 'injector.extraEnvironmentVars.lower\.case=sanitized' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="FOO")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "bar" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="FOOBAR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "foobar" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="LOWER_CASE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "sanitized" ]
}

#--------------------------------------------------------------------
# extra annotations

@test "injector/deployment: default annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/deployment: specify annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "injector/deployment: specify annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# agent port

@test "injector/deployment: default agentPort" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_LISTEN" ]

  local actual=$(echo $object |
      yq -r '.[0].value' | tee /dev/stderr)
  [ "${actual}" = ":8080" ]
}

@test "injector/deployment: custom agentPort" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.port=8443' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_LISTEN" ]

  local actual=$(echo $object |
      yq -r '.[0].value' | tee /dev/stderr)
  [ "${actual}" = ":8443" ]
}

#--------------------------------------------------------------------
# affinity

@test "injector/deployment: affinity set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .affinity? == null' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/deployment: affinity can be set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.affinity=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.affinity == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: affinity can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.affinity.podAntiAffinity=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.affinity.podAntiAffinity == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# topologySpreadConstraints

@test "injector/deployment: topologySpreadConstraints is null by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .topologySpreadConstraints? == null' | tee /dev/stderr)
}

@test "injector/deployment: topologySpreadConstraints can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.topologySpreadConstraints[0].foo=bar,injector.topologySpreadConstraints[1].baz=qux" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.topologySpreadConstraints == [{"foo": "bar"}, {"baz": "qux"}]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# tolerations

@test "injector/deployment: tolerations not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .tolerations? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: tolerations can be set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.tolerations=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: tolerations can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set "injector.tolerations[0].foo=bar,injector.tolerations[1].baz=qux" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == [{"foo": "bar"}, {"baz": "qux"}]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# nodeSelector

@test "injector/deployment: nodeSelector is not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/deployment: nodeSelector can be set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.nodeSelector=testing' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "testing" ]
}

@test "injector/deployment: nodeSelector can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.nodeSelector.beta\.kubernetes\.io/arch=amd64" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector == {"beta.kubernetes.io/arch": "amd64"}' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}


#--------------------------------------------------------------------
# priorityClassName

@test "injector/deployment: priorityClassName not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .priorityClassName? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: priorityClassName can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.priorityClassName=armaggeddon' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .priorityClassName == "armaggeddon"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
#--------------------------------------------------------------------
# OpenShift

@test "injector/deployment: OpenShift - runAsUser disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.securityContext.runAsUser | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/deployment: OpenShift - runAsGroup disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.securityContext.runAsGroup | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
#--------------------------------------------------------------------
# extra labels

@test "injector/deployment: specify extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# hostNetwork

@test "injector/deployment: injector.hostNetwork not set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.hostNetwork' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/deployment: injector.hostNetwork is set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.hostNetwork=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.hostNetwork' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: agent default resources" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_CPU_LIMIT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "500m" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_CPU_REQUEST")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "250m" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_MEM_LIMIT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "128Mi" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_MEM_REQUEST")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "64Mi" ]

}

@test "injector/deployment: can set agent default resources" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set 'injector.agentDefaults.cpuLimit=cpuLimit' \
      --set 'injector.agentDefaults.cpuRequest=cpuRequest' \
      --set 'injector.agentDefaults.memLimit=memLimit' \
      --set 'injector.agentDefaults.memRequest=memRequest' \
      --set 'injector.agentDefaults.ephemeralLimit=ephemeralLimit' \
      --set 'injector.agentDefaults.ephemeralRequest=ephemeralRequest' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_CPU_LIMIT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "cpuLimit" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_CPU_REQUEST")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "cpuRequest" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_MEM_LIMIT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "memLimit" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_MEM_REQUEST")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "memRequest" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_EPHEMERAL_LIMIT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "ephemeralLimit" ]

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_EPHEMERAL_REQUEST")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "ephemeralRequest" ]
}

@test "injector/deployment: agent default template" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_DEFAULT_TEMPLATE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "map" ]
}

@test "injector/deployment: can set agent default template" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set='injector.agentDefaults.template=json' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_DEFAULT_TEMPLATE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "json" ]
}

@test "injector/deployment: agent default template_config.exit_on_retry_failure" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TEMPLATE_CONFIG_EXIT_ON_RETRY_FAILURE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "true" ]
}

@test "injector/deployment: can set agent template_config.exit_on_retry_failure" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set='injector.agentDefaults.templateConfig.exitOnRetryFailure=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TEMPLATE_CONFIG_EXIT_ON_RETRY_FAILURE")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "false" ]
}

@test "injector/deployment: agent default template_config.static_secret_render_interval" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TEMPLATE_STATIC_SECRET_RENDER_INTERVAL")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "" ]
}

@test "injector/deployment: can set agent template_config.static_secret_render_interval" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set='injector.agentDefaults.templateConfig.staticSecretRenderInterval=1m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="AGENT_INJECT_TEMPLATE_STATIC_SECRET_RENDER_INTERVAL")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "1m" ]
}

@test "injector/deployment: strategy default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.strategy' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/deployment: strategy set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml  \
      --set="injector.strategy=testing"  \
      . | tee /dev/stderr |
      yq -r '.spec.strategy' | tee /dev/stderr)
  [ "${actual}" = "testing" ]
}

@test "injector/deployment: strategy can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set 'injector.strategy.rollingUpdate.maxUnavailable=1' \
      . | tee /dev/stderr |
      yq -r '.spec.strategy.rollingUpdate.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}
