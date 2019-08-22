#!/usr/bin/env bats

load _helpers

@test "server/ha-StatefulSet: enable with server.ha.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-StatefulSet: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'global.enabled=false' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ha-StatefulSet: image defaults to global.image" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'global.image=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'global.image=foo' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

#--------------------------------------------------------------------
# TLS

@test "server/ha-StatefulSet: tls disabled" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'global.tlsDisable=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[2].name' | tee /dev/stderr)
  [ "${actual}" = "VAULT_ADDR" ]

  local actual=$(echo $object |
     yq -r '.[2].value' | tee /dev/stderr)
  [ "${actual}" = "http://127.0.0.1:8200" ]
}
@test "server/ha-StatefulSet: tls enabled" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'global.tlsDisable=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[2].name' | tee /dev/stderr)
  [ "${actual}" = "VAULT_ADDR" ]

  local actual=$(echo $object |
     yq -r '.[2].value' | tee /dev/stderr)
  [ "${actual}" = "https://127.0.0.1:8200" ]
}

#--------------------------------------------------------------------
# updateStrategy

@test "server/ha-StatefulSet: OnDelete updateStrategy" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "OnDelete" ]
}

#--------------------------------------------------------------------
# affinity

@test "server/ha-StatefulSet: default affinity" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.affinity' | tee /dev/stderr)
  [ "${actual}" != "null" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.affinity=' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.affinity' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

#--------------------------------------------------------------------
# replicas

@test "server/ha-StatefulSet: default replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "3" ]
}

@test "server/ha-StatefulSet: custom replicas" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=10' \
      . | tee /dev/stderr |
      yq -r '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "10" ]
}

#--------------------------------------------------------------------
# resources

@test "server/ha-StatefulSet: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-StatefulSet: custom resources" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.requests.memory=256Mi' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.limits.memory=256Mi' \
      --set 'server.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]
}

#--------------------------------------------------------------------
# extraVolumes

@test "server/ha-StatefulSet: adds extra volume" {
  cd `chart_dir`
  # Test that it defines it
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
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
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
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

@test "server/ha-StatefulSet: adds extra volume custom mount path" {
  cd `chart_dir`
  # Test that it mounts it
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      --set 'server.extraVolumes[0].path=/custom/path' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/custom/path/foo" ]
}

@test "server/ha-StatefulSet: adds extra secret volume custom mount path" {
  cd `chart_dir`

  # Test that it mounts it
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraVolumes[0].type=configMap' \
      --set 'server.extraVolumes[0].name=foo' \
      --set 'server.extraVolumes[0].path=/custom/path' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/custom/path/foo" ]
}

@test "server/ha-StatefulSet: adds extra secret volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
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
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
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

#--------------------------------------------------------------------
# extraEnvironmentVars

@test "server/ha-StatefulSet: set extraEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraEnvironmentVars.FOO=bar' \
      --set 'server.extraEnvironmentVars.FOOBAR=foobar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[5].name' | tee /dev/stderr)
  [ "${actual}" = "FOO" ]

  local actual=$(echo $object |
      yq -r '.[5].value' | tee /dev/stderr)
  [ "${actual}" = "bar" ]

  local actual=$(echo $object |
      yq -r '.[6].name' | tee /dev/stderr)
  [ "${actual}" = "FOOBAR" ]

  local actual=$(echo $object |
      yq -r '.[6].value' | tee /dev/stderr)
  [ "${actual}" = "foobar" ]
}

#--------------------------------------------------------------------
# extraSecretEnvironmentVars

@test "server/ha-StatefulSet: set extraSecretEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.extraSecretEnvironmentVars[0].envName=ENV_FOO_0' \
      --set 'server.extraSecretEnvironmentVars[0].secretName=secret_name_0' \
      --set 'server.extraSecretEnvironmentVars[0].secretKey=secret_key_0' \
      --set 'server.extraSecretEnvironmentVars[1].envName=ENV_FOO_1' \
      --set 'server.extraSecretEnvironmentVars[1].secretName=secret_name_1' \
      --set 'server.extraSecretEnvironmentVars[1].secretKey=secret_key_1' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.[5].name' | tee /dev/stderr)
  [ "${actual}" = "ENV_FOO_0" ]
  local actual=$(echo $object |
      yq -r '.[5].valueFrom.secretKeyRef.name' | tee /dev/stderr)
  [ "${actual}" = "secret_name_0" ]
  local actual=$(echo $object |
      yq -r '.[5].valueFrom.secretKeyRef.key' | tee /dev/stderr)
  [ "${actual}" = "secret_key_0" ]

  local actual=$(echo $object |
      yq -r '.[6].name' | tee /dev/stderr)
  [ "${actual}" = "ENV_FOO_1" ]
  local actual=$(echo $object |
      yq -r '.[6].valueFrom.secretKeyRef.name' | tee /dev/stderr)
  [ "${actual}" = "secret_name_1" ]
  local actual=$(echo $object |
      yq -r '.[6].valueFrom.secretKeyRef.key' | tee /dev/stderr)
  [ "${actual}" = "secret_key_1" ]
}

#--------------------------------------------------------------------
# storage class

@test "server/ha-StatefulSet: no storage by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]
}


@test "server/ha-StatefulSet: cant set data storage" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      --set 'server.dataStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-StatefulSet: can set storageClass" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.auditStorage.storageClass=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates[0].spec.storageClassName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
}

@test "server/ha-StatefulSet: can disable storage" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "server/ha-StatefulSet: no data storage" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=false' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.auditStorage.enabled=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.volumeClaimTemplates | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "server/ha-StatefulSet: tolerations not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec | .tolerations? == null' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-StatefulSet: tolerations can be set" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.tolerations=foobar' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.tolerations == "foobar"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-StatefulSet: nodeSelector is not set by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ha-StatefulSet: specified nodeSelector" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-statefulset.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.nodeSelector=testing' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.nodeSelector' | tee /dev/stderr)
  [ "${actual}" = "testing" ]
}
