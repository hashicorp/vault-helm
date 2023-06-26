#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Daemonset

# Enabled
@test "csi/daemonset: created only when enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-daemonset.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

# namespace
@test "csi/daemonset: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

# priorityClassName

@test "csi/daemonset: priorityClassName not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .priorityClassName? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: priorityClassName can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.priorityClassName=armaggeddon' \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .priorityClassName == "armaggeddon"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

# serviceAccountName reference name
@test "csi/daemonset: serviceAccountName reference name" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-csi-provider" ]
}

# Image
@test "csi/daemonset: images are configurable" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.image.repository=Image1" \
      --set "csi.image.tag=0.0.1" \
      --set "csi.image.pullPolicy=PullPolicy1" \
      --set "csi.agent.image.repository=Image2" \
      --set "csi.agent.image.tag=0.0.2" \
      --set "csi.agent.image.pullPolicy=PullPolicy2" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.[0].image' | tee /dev/stderr)
  [ "${actual}" = "Image1:0.0.1" ]
  local actual=$(echo $object |
      yq -r '.[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "PullPolicy1" ]
  local actual=$(echo $object |
      yq -r '.[1].image' | tee /dev/stderr)
  [ "${actual}" = "Image2:0.0.2" ]
  local actual=$(echo $object |
      yq -r '.[1].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "PullPolicy2" ]
}

@test "csi/daemonset: Custom imagePullSecrets" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set "csi.enabled=true" \
      --set 'global.imagePullSecrets[0].name=foo' \
      --set 'global.imagePullSecrets[1].name=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.imagePullSecrets' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '. | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]

  local actual=$(echo $object |
     yq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.[1].name' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: Custom imagePullSecrets - string array" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set "csi.enabled=true" \
      --set 'global.imagePullSecrets[0]=foo' \
      --set 'global.imagePullSecrets[1]=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.imagePullSecrets' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '. | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]

  local actual=$(echo $object |
     yq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.[1].name' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: default imagePullSecrets" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.imagePullSecrets' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

# Debug arg
@test "csi/daemonset: debug arg is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[1]' | tee /dev/stderr)
  [ "${actual}" = "--debug=false" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.debug=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[1]' | tee /dev/stderr)
  [ "${actual}" = "--debug=true" ]
}

# HMAC secret arg
@test "csi/daemonset: HMAC secret arg is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[2]' | tee /dev/stderr)
  [ "${actual}" = "--hmac-secret-name=vault-csi-provider-hmac-key" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.hmacSecretName=foo" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[2]' | tee /dev/stderr)
  [ "${actual}" = "--hmac-secret-name=foo" ]
}

# Extra args
@test "csi/daemonset: extra args can be passed" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args | length' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.extraArgs={--foo=bar,--bar baz,first}" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0]')
  local actual=$(echo $object |
      yq -r '.args | length' | tee /dev/stderr)
  [ "${actual}" = "6" ]
  local actual=$(echo $object |
      yq -r '.args[3]' | tee /dev/stderr)
  [ "${actual}" = "--foo=bar" ]
  local actual=$(echo $object |
      yq -r '.args[4]' | tee /dev/stderr)
  [ "${actual}" = "--bar baz" ]
  local actual=$(echo $object |
      yq -r '.args[5]' | tee /dev/stderr)
  [ "${actual}" = "first" ]
}

# updateStrategy
@test "csi/daemonset: updateStrategy is configurable" {
  cd `chart_dir`
  # Default
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "RollingUpdate" ]

  # OnDelete
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.daemonSet.updateStrategy.type=OnDelete" \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "OnDelete" ]

  # Max unavailable
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.daemonSet.updateStrategy.maxUnavailable=25%" \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.rollingUpdate.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "25%" ]
}

#--------------------------------------------------------------------
# Extra annotations
@test "csi/daemonset: default csi.daemonSet.annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: specify csi.daemonSet.annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.daemonSet.annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: default csi.pod.annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: specify csi.pod.annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.pod.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.pod.annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.pod.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: tolerations not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .tolerations? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: tolerations can be set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.pod.tolerations=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: tolerations can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set "csi.pod.tolerations[0].foo=bar,csi.pod.tolerations[1].baz=qux" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == [{"foo": "bar"}, {"baz": "qux"}]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# nodeSelector
@test "csi/daemonset: nodeSelector not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .nodeSelector? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: nodeSelector can be set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.pod.nodeSelector=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: nodeSelector can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set "csi.pod.nodeSelector.foo=bar,csi.pod.nodeSelector.baz=qux" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector.foo == "bar" and .spec.template.spec.nodeSelector.baz == "qux"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# affinity
@test "csi/daemonset: affinity not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .affinity? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: affinity can be set as string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.pod.affinity=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.affinity == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "csi/daemonset: affinity can be set as YAML" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set "csi.pod.affinity.podAntiAffinity=foobar" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.affinity.podAntiAffinity == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# Extra Labels

@test "csi/daemonset: specify csi.daemonSet.extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.pod.extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.pod.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}


#--------------------------------------------------------------------
# volumes

@test "csi/daemonset: csi.volumes adds volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.volumes[0].name=plugins' \
      --set 'csi.volumes[0].emptyDir=\{\}' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "plugins")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.emptyDir' | tee /dev/stderr)
  [ "${actual}" = "{}" ]
}

@test "csi/daemonset: csi providersDir default" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "providervol")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.hostPath.path' | tee /dev/stderr)
  [ "${actual}" = "/etc/kubernetes/secrets-store-csi-providers" ]
}

@test "csi/daemonset: csi providersDir override " {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.providersDir=/alt/csi-prov-dir' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "providervol")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.hostPath.path' | tee /dev/stderr)
  [ "${actual}" = "/alt/csi-prov-dir" ]
}

#--------------------------------------------------------------------
# volumeMounts

@test "csi/daemonset: csi.volumeMounts adds volume mounts" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.volumeMounts[0].name=plugins' \
      --set 'csi.volumeMounts[0].mountPath=/usr/local/libexec/vault' \
      --set 'csi.volumeMounts[0].readOnly=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "plugins")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/usr/local/libexec/vault" ]

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# Readiness/liveness probes

@test "csi/daemonset: csi.livenessProbe is configurable" {
  cd `chart_dir`

  # Test the defaults
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "2" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "1" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  # Test it is configurable
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.livenessProbe.failureThreshold=10' \
      --set 'csi.livenessProbe.initialDelaySeconds=11' \
      --set 'csi.livenessProbe.periodSeconds=12' \
      --set 'csi.livenessProbe.successThreshold=13' \
      --set 'csi.livenessProbe.timeoutSeconds=14' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "10" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "11" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "12" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "13" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "14" ]
}

@test "csi/daemonset: csi.readinessProbe is configurable" {
  cd `chart_dir`

  # Test the defaults
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "2" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "1" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  # Test it is configurable
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.readinessProbe.failureThreshold=10' \
      --set 'csi.readinessProbe.initialDelaySeconds=11' \
      --set 'csi.readinessProbe.periodSeconds=12' \
      --set 'csi.readinessProbe.successThreshold=13' \
      --set 'csi.readinessProbe.timeoutSeconds=14' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "10" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "11" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "12" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "13" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "14" ]
}

@test "csi/daemonset: VAULT_ADDR defaults to Agent unix socket" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "unix:///var/run/vault/agent.sock" ]
}

@test "csi/daemonset: VAULT_ADDR remains pointed to Agent unix socket if external Vault" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'global.externalVaultAddr=http://vault-outside' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "unix:///var/run/vault/agent.sock" ]
}

@test "csi/daemonset: with only injector.externalVaultAddr" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.agent.enabled=false' \
      --release-name not-external-test \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://not-external-test-vault.default.svc:8200" ]
}

@test "csi/daemonset: with global.externalVaultAddr" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.agent.enabled=false' \
      --set 'global.externalVaultAddr=http://vault-outside' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="VAULT_ADDR")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "http://vault-outside" ]
}

#--------------------------------------------------------------------
# securityContext

@test "csi/daemonset: default csi.daemonSet.securityContext.pod" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: default csi.daemonSet.securityContext.container" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: specify csi.daemonSet.securityContext.pod yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.securityContext.pod.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.daemonSet.securityContext.container yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.securityContext.container.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.daemonSet.securityContext.container yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.securityContext.container=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].securityContext.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# Agent sidecar configurables

@test "csi/daemonset: Agent sidecar enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "csi/daemonset: Agent sidecar can pass extra args" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.agent.extraArgs[0]=-config=extra-config.hcl' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].args[2]' | tee /dev/stderr)
  [ "${actual}" = "-config=extra-config.hcl" ]
}

@test "csi/daemonset: Agent log level settable" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.agent.logLevel=error' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="VAULT_LOG_LEVEL")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "error" ]
}

@test "csi/daemonset: Agent log format settable" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.agent.logFormat=json' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].env' | tee /dev/stderr)

  local value=$(echo $object |
      yq -r 'map(select(.name=="VAULT_LOG_FORMAT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "json" ]
}

@test "csi/daemonset: Agent default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: Agent custom resources" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.agent.resources.requests.memory=256Mi' \
      --set 'csi.agent.resources.requests.cpu=250m' \
      --set 'csi.agent.resources.limits.memory=512Mi' \
      --set 'csi.agent.resources.limits.cpu=500m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].resources' | tee /dev/stderr)
  local value=$(echo $object |
      yq -r '.requests.memory' | tee /dev/stderr)
  [ "${value}" = "256Mi" ]

  local value=$(echo $object |
      yq -r '.requests.cpu' | tee /dev/stderr)
  [ "${value}" = "250m" ]

  local value=$(echo $object |
      yq -r '.limits.memory' | tee /dev/stderr)
  [ "${value}" = "512Mi" ]

  local value=$(echo $object |
      yq -r '.limits.cpu' | tee /dev/stderr)
  [ "${value}" = "500m" ]
}
