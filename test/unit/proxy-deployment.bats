#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# disable / enable proxy deployment

@test "proxy/deployment: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-deployment.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/deployment: enable with proxy.enabled=true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/deployment: enable with global.enabled false and proxy.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'global.enabled=false' \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/deployment: enable with proxy.enabled dash and global.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=-' \
      --set 'global.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/deployment: disable with proxy.enabled dash and global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=-' \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# metadata

@test "proxy/deployment: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "default" ]
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'global.namespace=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/deployment: selector labels" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels["app.kubernetes.io/name"]')" = "vault-proxy" ]
  [ "$(echo "$output" | yq -r '.spec.selector.matchLabels.component')" = "proxy" ]
  [ "$(echo "$output" | yq -r '.spec.template.metadata.labels.component')" = "proxy" ]
}

@test "proxy/deployment: specify extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# annotations

@test "proxy/deployment: config checksum annotation is set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations["vault.hashicorp.com/config-checksum"]' | tee /dev/stderr)
  [ "${actual}" != "null" ]
}

@test "proxy/deployment: config checksum annotation changes with the config" {
  cd `chart_dir`
  local default=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations["vault.hashicorp.com/config-checksum"]' | tee /dev/stderr)
  local custom=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.config=cache {}' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations["vault.hashicorp.com/config-checksum"]' | tee /dev/stderr)
  [ "${default}" != "${custom}" ]
}

@test "proxy/deployment: specify annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/deployment: specify annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# image, replicas, command

@test "proxy/deployment: default image is proxy.image.repository:tag" {
  cd `chart_dir`
  # Read the expected image from values.yaml rather than pinning a version, so
  # this does not need updating every time the default Vault image is bumped
  local expected=$(yq -r '.proxy.image | .repository + ":" + .tag' values.yaml | tee /dev/stderr)

  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "${expected}" ]
}

@test "proxy/deployment: specify image and pullPolicy" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.image.repository=foo' \
      --set 'proxy.image.tag=1.2.3' \
      --set 'proxy.image.pullPolicy=Always' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].image')" = "foo:1.2.3" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].imagePullPolicy')" = "Always" ]
}

@test "proxy/deployment: default replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "proxy/deployment: specify replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.replicas=3' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "3" ]
}

@test "proxy/deployment: runs vault proxy with the mounted config" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].command[0]')" = "vault" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].args[0]')" = "proxy" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].args[1]')" = "-config=/etc/vault/config.hcl" ]
}

@test "proxy/deployment: specify extraArgs" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.extraArgs[0]=-log-file=/tmp/proxy.log' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[2]' | tee /dev/stderr)
  [ "${actual}" = "-log-file=/tmp/proxy.log" ]
}

#--------------------------------------------------------------------
# environment

@test "proxy/deployment: default log level and format" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].env[] | select(.name == "VAULT_LOG_LEVEL") | .value')" = "info" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].env[] | select(.name == "VAULT_LOG_FORMAT") | .value')" = "standard" ]
}

@test "proxy/deployment: specify log level and format" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.logLevel=debug' \
      --set 'proxy.logFormat=json' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].env[] | select(.name == "VAULT_LOG_LEVEL") | .value')" = "debug" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].env[] | select(.name == "VAULT_LOG_FORMAT") | .value')" = "json" ]
}

@test "proxy/deployment: specify extraEnvironmentVars" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.extraEnvironmentVars.VAULT_CACERT=/vault/tls/ca.crt' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[] | select(.name == "VAULT_CACERT") | .value' | tee /dev/stderr)
  [ "${actual}" = "/vault/tls/ca.crt" ]
}

@test "proxy/deployment: specify extraSecretEnvironmentVars" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.extraSecretEnvironmentVars[0].envName=AWS_SECRET_ACCESS_KEY' \
      --set 'proxy.extraSecretEnvironmentVars[0].secretName=vault' \
      --set 'proxy.extraSecretEnvironmentVars[0].secretKey=AWS_SECRET_ACCESS_KEY' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[] | select(.name == "AWS_SECRET_ACCESS_KEY")' | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.valueFrom.secretKeyRef.name')" = "vault" ]
  [ "$(echo "$output" | yq -r '.valueFrom.secretKeyRef.key')" = "AWS_SECRET_ACCESS_KEY" ]
}

#--------------------------------------------------------------------
# resources

@test "proxy/deployment: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/deployment: specify resources" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.resources.requests.memory=256Mi' \
      --set 'proxy.resources.limits.memory=512Mi' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].resources.requests.memory')" = "256Mi" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].resources.limits.memory')" = "512Mi" ]
}

#--------------------------------------------------------------------
# securityContext

@test "proxy/deployment: default pod securityContext" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.securityContext.runAsNonRoot')" = "true" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.securityContext.runAsUser')" = "100" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.securityContext.fsGroup')" = "1000" ]
}

@test "proxy/deployment: default container securityContext" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation')" = "false" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]')" = "ALL" ]
}

@test "proxy/deployment: no default securityContext on OpenShift" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'global.openshift=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.securityContext')" = "null" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].securityContext')" = "null" ]
}

@test "proxy/deployment: specify pod securityContext yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.securityContext.pod.runAsUser=200' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "200" ]
}

@test "proxy/deployment: specify container securityContext yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.securityContext.container.readOnlyRootFilesystem=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# scheduling

@test "proxy/deployment: no affinity by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.affinity' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/deployment: specify affinity string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.affinity=nodeAffinity: {{ .Release.Name }}' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.affinity.nodeAffinity' | tee /dev/stderr)
  [ "${actual}" = "release-name" ]
}

@test "proxy/deployment: specify tolerations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.tolerations[0].key=dedicated' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.tolerations[0].key' | tee /dev/stderr)
  [ "${actual}" = "dedicated" ]
}

@test "proxy/deployment: specify nodeSelector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.nodeSelector.disktype=ssd' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.nodeSelector.disktype' | tee /dev/stderr)
  [ "${actual}" = "ssd" ]
}

@test "proxy/deployment: specify topologySpreadConstraints" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.topologySpreadConstraints[0].maxSkew=1' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.topologySpreadConstraints[0].maxSkew' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "proxy/deployment: specify priorityClassName" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.priorityClassName=high-priority' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.priorityClassName' | tee /dev/stderr)
  [ "${actual}" = "high-priority" ]
}

@test "proxy/deployment: specify strategy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.strategy.type=Recreate' \
      . | tee /dev/stderr |
      yq -r '.spec.strategy.type' | tee /dev/stderr)
  [ "${actual}" = "Recreate" ]
}

#--------------------------------------------------------------------
# probes and ports

@test "proxy/deployment: default probes are tcp checks on the proxy port" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].livenessProbe.tcpSocket.port')" = "8100" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.tcpSocket.port')" = "8100" ]
}

@test "proxy/deployment: probe with path uses httpGet on the listener" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.readinessProbe.path=/v1/sys/health?standbyok=true&perfstandbyok=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.path')" = "/v1/sys/health?standbyok=true&perfstandbyok=true" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.port')" = "8100" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.scheme')" = "HTTP" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.tcpSocket')" = "null" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].livenessProbe.tcpSocket.port')" = "8100" ]
}

@test "proxy/deployment: probe scheme follows proxy.tlsDisable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.tlsDisable=false' \
      --set 'proxy.livenessProbe.path=/v1/sys/health' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe.httpGet.scheme' | tee /dev/stderr)
  [ "${actual}" = "HTTPS" ]
}

@test "proxy/deployment: specify probe settings" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.livenessProbe.failureThreshold=10' \
      --set 'proxy.readinessProbe.periodSeconds=30' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].livenessProbe.failureThreshold')" = "10" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.periodSeconds')" = "30" ]
}

@test "proxy/deployment: specify port" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.port=8300' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].ports[0].containerPort')" = "8300" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].livenessProbe.tcpSocket.port')" = "8300" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.tcpSocket.port')" = "8300" ]
}

@test "proxy/deployment: probe ports can target a different listener" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.livenessProbe.port=8101' \
      --set 'proxy.readinessProbe.path=/v1/sys/health?standbyok=true&perfstandbyok=true' \
      --set 'proxy.readinessProbe.port=8102' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].livenessProbe.tcpSocket.port')" = "8101" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.port')" = "8102" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].ports[0].containerPort')" = "8100" ]
}

#--------------------------------------------------------------------
# volumes

@test "proxy/deployment: config is mounted from the ConfigMap" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr)
  [ "$(echo "$output" | yq -r '.spec.template.spec.volumes[0].configMap.name')" = "release-name-vault-proxy-config" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].volumeMounts[0].mountPath')" = "/etc/vault/config.hcl" ]
  [ "$(echo "$output" | yq -r '.spec.template.spec.containers[0].volumeMounts[0].readOnly')" = "true" ]
}

@test "proxy/deployment: proxy.volumes adds volume" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.volumes[0].name=plugins' \
      --set 'proxy.volumes[0].emptyDir=' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "plugins") | .name' | tee /dev/stderr)
  [ "${actual}" = "plugins" ]
}

@test "proxy/deployment: proxy.volumeMounts adds volume mount" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.volumeMounts[0].name=plugins' \
      --set 'proxy.volumeMounts[0].mountPath=/usr/local/libexec/vault' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "plugins") | .mountPath' | tee /dev/stderr)
  [ "${actual}" = "/usr/local/libexec/vault" ]
}

#--------------------------------------------------------------------
# serviceAccount

@test "proxy/deployment: default serviceAccountName" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-proxy" ]
}

@test "proxy/deployment: specify serviceAccount name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.name=custom-proxy-sa' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "custom-proxy-sa" ]
}

@test "proxy/deployment: serviceAccountName is default when create is false" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.serviceAccount.create=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "default" ]
}

#--------------------------------------------------------------------
# imagePullSecrets

@test "proxy/deployment: specify global.imagePullSecrets" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-deployment.yaml \
      --set 'proxy.enabled=true' \
      --set 'global.imagePullSecrets[0].name=my-secret' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.imagePullSecrets[0].name' | tee /dev/stderr)
  [ "${actual}" = "my-secret" ]
}
