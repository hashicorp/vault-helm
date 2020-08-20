#!/usr/bin/env bats

load _helpers

@test "server/standalone-StatefulSet: default server.standalone.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: enable with server.standalone.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.enabled=false' \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/standalone-StatefulSet: disable with injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/standalone-StatefulSet: image defaults to server.image.repository:tag" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=1.2.3' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=1.2.3' \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]
}

@test "server/standalone-StatefulSet: image tag defaults to latest" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:latest" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=' \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:latest" ]
}

@test "server/standalone-StatefulSet: default imagePullPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "IfNotPresent" ]
}

@test "server/standalone-StatefulSet: Custom imagePullPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.image.pullPolicy=Always' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "Always" ]
}

@test "server/standalone-StatefulSet: Custom imagePullSecrets" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.imagePullSecrets[0].name=foo' \
      --set 'global.imagePullSecrets[1].name=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.imagePullSecrets' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.[1].name' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/standalone-StatefulSet: default imagePullSecrets" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.imagePullSecrets' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

#--------------------------------------------------------------------
# updateStrategy

@test "server/standalone-StatefulSet: OnDelete updateStrategy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "OnDelete" ]
}

#--------------------------------------------------------------------
# replicas

@test "server/standalone-StatefulSet: default replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "server/standalone-StatefulSet: custom replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.replicas=100' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.standalone.replicas=100' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

#--------------------------------------------------------------------
# resources

@test "server/standalone-StatefulSet: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/standalone-StatefulSet: custom resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.resources.requests.memory=256Mi' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.resources.limits.memory=256Mi' \
      --set 'server.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]
}

#--------------------------------------------------------------------
# extraVolumes

@test "server/standalone-StatefulSet: server.extraVolumes adds extra volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.configMap.name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.configMap.secretName' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.configMap.name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.configMap.secretName' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/vault/userconfig/foo" ]

  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/vault/userconfig/foo" ]
}

@test "server/standalone-StatefulSet: server.extraVolumes adds extra secret volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraVolumes[0].type=secret' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.secret.name' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(echo $object |
      yq -r '.secret.secretName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.extraVolumes[0].type=secret' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.secret.name' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(echo $object |
      yq -r '.secret.secretName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/vault/userconfig/foo" ]

  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/vault/userconfig/foo" ]
}

@test "server/standalone-StatefulSet: can mount audit" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.auditStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "audit")' | tee /dev/stderr)
}

#--------------------------------------------------------------------
# volumes

@test "server/standalone-StatefulSet: server.volumes adds volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.volumes[0].name=plugins' \
      --set 'server.volumes[0].emptyDir=\{\}' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "plugins")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.emptyDir' | tee /dev/stderr)
  [ "${actual}" = "{}" ]
}

#--------------------------------------------------------------------
# volumeMounts

@test "server/standalone-StatefulSet: server.volumeMounts adds volumeMount" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.volumeMounts[0].name=plugins' \
      --set 'server.volumeMounts[0].mountPath=/usr/local/libexec/vault' \
      --set 'server.volumeMounts[0].readOnly=true' \
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
# extraEnvironmentVars

@test "server/standalone-StatefulSet: set extraEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.stanadlone.enabled=true' \
      --set 'server.extraEnvironmentVars.FOO=bar' \
      --set 'server.extraEnvironmentVars.FOOBAR=foobar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[11].name' | tee /dev/stderr)
  [ "${actual}" = "FOO" ]

  local actual=$(echo $object |
      yq -r '.[11].value' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(echo $object |
      yq -r '.[12].name' | tee /dev/stderr)
  [ "${actual}" = "FOOBAR" ]

  local actual=$(echo $object |
      yq -r '.[12].value' | tee /dev/stderr)
  [ "${actual}" = "foobar" ]

  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraEnvironmentVars.FOO=bar' \
      --set 'server.extraEnvironmentVars.FOOBAR=foobar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[11].name' | tee /dev/stderr)
  [ "${actual}" = "FOO" ]

  local actual=$(echo $object |
      yq -r '.[11].value' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(echo $object |
      yq -r '.[12].name' | tee /dev/stderr)
  [ "${actual}" = "FOOBAR" ]

  local actual=$(echo $object |
      yq -r '.[12].value' | tee /dev/stderr)
  [ "${actual}" = "foobar" ]
}

#--------------------------------------------------------------------
# storage class

@test "server/standalone-StatefulSet: storageClass on claim by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}


@test "server/standalone-StatefulSet: can set storageClass" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.dataStorage.enabled=true' \
      --set 'server.dataStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.auditStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.auditStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[1].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "server/standalone-StatefulSet: can disable storage" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.auditStorage.enabled=fa;se' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]
}

@test "server/standalone-StatefulSet: affinity is set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec.affinity["podAntiAffinity"]? != null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: affinity can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.affinity=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.affinity == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: tolerations not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .tolerations? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: tolerations can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.tolerations=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: nodeSelector is not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/standalone-StatefulSet: specified nodeSelector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.nodeSelector=testing' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "testing" ]
}

#--------------------------------------------------------------------
# extraInitContainers

@test "server/standalone-StatefulSet: adds extra init containers" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraInitContainers[0].image=test-image' \
      --set 'server.extraInitContainers[0].name=test-container' \
      --set 'server.extraInitContainers[0].ports[0].name=test-port' \
      --set 'server.extraInitContainers[0].ports[0].containerPort=9410' \
      --set 'server.extraInitContainers[0].ports[0].protocol=TCP' \
      --set 'server.extraInitContainers[0].env[0].name=TEST_ENV' \
      --set 'server.extraInitContainers[0].env[0].value=test_env_value' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.initContainers[] | select(.name == "test-container")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.name' | tee /dev/stderr)
  [ "${actual}" = "test-container" ]

  local actual=$(echo $object |
      yq -r '.image' | tee /dev/stderr)
  [ "${actual}" = "test-image" ]

  local actual=$(echo $object |
      yq -r '.ports[0].name' | tee /dev/stderr)
  [ "${actual}" = "test-port" ]

  local actual=$(echo $object |
      yq -r '.ports[0].containerPort' | tee /dev/stderr)
  [ "${actual}" = "9410" ]

  local actual=$(echo $object |
      yq -r '.ports[0].protocol' | tee /dev/stderr)
  [ "${actual}" = "TCP" ]

  local actual=$(echo $object |
      yq -r '.env[0].name' | tee /dev/stderr)
  [ "${actual}" = "TEST_ENV" ]

  local actual=$(echo $object |
      yq -r '.env[0].value' | tee /dev/stderr)
  [ "${actual}" = "test_env_value" ]

}

@test "server/standalone-StatefulSet: add two extra init containers" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraInitContainers[0].image=test-image' \
      --set 'server.extraInitContainers[0].name=test-container' \
      --set 'server.extraInitContainers[1].image=test-image' \
      --set 'server.extraInitContainers[1].name=test-container-2' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.initContainers' | tee /dev/stderr)

  local containers_count=$(echo $object |
      yq -r 'length' | tee /dev/stderr)
  [ "${containers_count}" = 2 ]

}

#--------------------------------------------------------------------
# extraContainers

@test "server/standalone-StatefulSet: adds extra containers" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraContainers[0].image=test-image' \
      --set 'server.extraContainers[0].name=test-container' \
      --set 'server.extraContainers[0].ports[0].name=test-port' \
      --set 'server.extraContainers[0].ports[0].containerPort=9410' \
      --set 'server.extraContainers[0].ports[0].protocol=TCP' \
      --set 'server.extraContainers[0].env[0].name=TEST_ENV' \
      --set 'server.extraContainers[0].env[0].value=test_env_value' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[] | select(.name == "test-container")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.name' | tee /dev/stderr)
  [ "${actual}" = "test-container" ]

  local actual=$(echo $object |
      yq -r '.image' | tee /dev/stderr)
  [ "${actual}" = "test-image" ]

  local actual=$(echo $object |
      yq -r '.ports[0].name' | tee /dev/stderr)
  [ "${actual}" = "test-port" ]

  local actual=$(echo $object |
      yq -r '.ports[0].containerPort' | tee /dev/stderr)
  [ "${actual}" = "9410" ]

  local actual=$(echo $object |
      yq -r '.ports[0].protocol' | tee /dev/stderr)
  [ "${actual}" = "TCP" ]

  local actual=$(echo $object |
      yq -r '.env[0].name' | tee /dev/stderr)
  [ "${actual}" = "TEST_ENV" ]

  local actual=$(echo $object |
      yq -r '.env[0].value' | tee /dev/stderr)
  [ "${actual}" = "test_env_value" ]

}

@test "server/standalone-StatefulSet: add two extra containers" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.extraContainers[0].image=test-image' \
      --set 'server.extraContainers[0].name=test-container' \
      --set 'server.extraContainers[1].image=test-image' \
      --set 'server.extraContainers[1].name=test-container-2' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers' | tee /dev/stderr)

  local containers_count=$(echo $object |
      yq -r 'length' | tee /dev/stderr)
  [ "${containers_count}" = 3 ]

}

@test "server/standalone-StatefulSet: no extra containers added" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers' | tee /dev/stderr)

  local containers_count=$(echo $object |
      yq -r 'length' | tee /dev/stderr)
  [ "${containers_count}" = 1 ]
}

# sharedProcessNamespace

@test "server/standalone-StatefulSet: shareProcessNamespace disabled by default" {
  cd `chart_dir`

  # Test that it defines it
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.shareProcessNamespace' | tee /dev/stderr)

  [ "${actual}" = "null" ]
}

@test "server/standalone-StatefulSet: shareProcessNamespace enabled" {
  cd `chart_dir`

  # Test that it defines it
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.shareProcessNamespace=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.shareProcessNamespace' | tee /dev/stderr)

  [ "${actual}" = "true" ]
}

# extra labels

@test "server/standalone-StatefulSet: specify extraLabels" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.extraLabels.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.labels.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

# extra annotations

@test "server/standalone-StatefulSet: default statefulSet.annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/standalone-StatefulSet: specify statefulSet.annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.statefulSet.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/standalone-StatefulSet: specify statefulSet.annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.statefulSet.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# Security Contexts
@test "server/standalone-StatefulSet: uid default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "100" ]
}

@test "server/standalone-StatefulSet: uid configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.uid=2000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

@test "server/standalone-StatefulSet: gid default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "1000" ]
}

@test "server/standalone-StatefulSet: gid configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.gid=2000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

@test "server/standalone-StatefulSet: fsgroup default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "1000" ]
}

@test "server/standalone-StatefulSet: fsgroup configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.gid=2000' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

#--------------------------------------------------------------------
# health checks

@test "server/standalone-StatefulSet: readinessProbe default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe.exec.command[2]' | tee /dev/stderr)
  [ "${actual}" = "vault status -tls-skip-verify" ]
}

@test "server/standalone-StatefulSet: readinessProbe configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.readinessProbe.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}


@test "server/standalone-StatefulSet: livenessProbe default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/standalone-StatefulSet: livenessProbe configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.livenessProbe.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe.httpGet.path' | tee /dev/stderr)
  [ "${actual}" = "/v1/sys/health?standbyok=true" ]
}

@test "server/standalone-StatefulSet: livenessProbe initialDelaySeconds default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.livenessProbe.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "60" ]
}

@test "server/standalone-StatefulSet: livenessProbe initialDelaySeconds configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.livenessProbe.enabled=true' \
      --set 'server.livenessProbe.initialDelaySeconds=30' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "30" ]
}

@test "server/standalone-StatefulSet: add extraArgs" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.extraArgs=foobar' \
      . | tee /dev/stderr |
       yq -r '.spec.template.spec.containers[0].args[0]' | tee /dev/stderr)
  [[ "${actual}" = *"foobar"* ]]
}

#--------------------------------------------------------------------
# preStop
@test "server/standalone-StatefulSet: preStop sleep duration default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      . | tee /dev/stderr |
       yq -r '.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]' | tee /dev/stderr)
  [[ "${actual}" = "sleep 5 &&"* ]]
}

@test "server/standalone-StatefulSet: preStop sleep duration 10" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.preStopSleepSeconds=10' \
      . | tee /dev/stderr |
       yq -r '.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]' | tee /dev/stderr)
  [[ "${actual}" = "sleep 10 &&"* ]]
}

@test "server/standalone-StatefulSet: vault port name is http, when tlsDisable is true" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'global.tlsDisable=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].ports | map(select(.containerPort==8200)) | .[] .name' | tee /dev/stderr)
  [ "${actual}" = "http" ]
}

@test "server/standalone-StatefulSet: vault replication port name is http-rep, when tlsDisable is true" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'global.tlsDisable=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].ports | map(select(.containerPort==8202)) | .[] .name' | tee /dev/stderr)
  [ "${actual}" = "http-rep" ]
}

@test "server/standalone-StatefulSet: vault port name is https, when tlsDisable is false" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].ports | map(select(.containerPort==8200)) | .[] .name' | tee /dev/stderr)
  [ "${actual}" = "https" ]
}

@test "server/standalone-StatefulSet: vault replication port name is https-rep, when tlsDisable is false" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].ports | map(select(.containerPort==8202)) | .[] .name' | tee /dev/stderr)
  [ "${actual}" = "https-rep" ]
}

#--------------------------------------------------------------------
# annotations
@test "server/standalone-StatefulSet: generic annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: auditStorage volumeClaim annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.auditStorage.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[1].metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: dataStorage volumeClaim annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.dataStorage.enabled=true' \
      --set 'server.dataStorage.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: auditStorage volumeClaim annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.auditStorage.annotations.vaultIsAwesome=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[1].metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: dataStorage volumeClaim annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.dataStorage.enabled=true' \
      --set 'server.dataStorage.annotations.vaultIsAwesome=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-standby-Service: generic annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml \
      --set 'server.annotations.vaultIsAwesome=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# priorityClassName

@test "server/standalone-StatefulSet: priorityClassName not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .priorityClassName? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-StatefulSet: priorityClassName can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.priorityClassName=armaggeddon' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .priorityClassName == "armaggeddon"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

# postStart
@test "server/standalone-StatefulSet: postStart disabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].lifecycle.postStart' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/standalone-StatefulSet: postStart can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set='server.postStart={/bin/sh,-c,sleep}' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].lifecycle.postStart.exec.command[0]' | tee /dev/stderr)
  [ "${actual}" = "/bin/sh" ]
}

#--------------------------------------------------------------------
# OpenShift

@test "server/standalone-StatefulSet: OpenShift - runAsUser disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.securityContext.runAsUser | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/standalone-StatefulSet: OpenShift - runAsGroup disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.securityContext.runAsGroup | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

#--------------------------------------------------------------------
# serviceAccount

@test "server/standalone-StatefulSet: serviceAccount.name is set" {
  cd `chart_dir`

 local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.serviceAccount.create=false' \
      --set 'server.serviceAccount.name=user-defined-ksa' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "user-defined-ksa" ]

 local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.serviceAccount.create=true' \
      --set 'server.serviceAccount.name=user-defined-ksa' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "user-defined-ksa" ]
}

@test "server/standalone-StatefulSet: serviceAccount.name is not set" {
 cd `chart_dir`

 local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.serviceAccount.create=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "default" ]

 local actual=$(helm template \
      --show-only templates/server-statefulset.yaml  \
      --set 'server.serviceAccount.create=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.serviceAccountName' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault" ]


}
