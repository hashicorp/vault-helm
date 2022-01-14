#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# disable / enable server deployment

@test "server/server-test-Pod: disabled server.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/server-test-Pod: disabled server.enabled random string" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.enabled=blabla' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/server-test-Pod: enabled server.enabled explicit true" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------

@test "server/standalone-server-test-Pod: default server.standalone.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-server-test-Pod: enable with server.standalone.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/ha-server-test-Pod: enable with server.ha.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/standalone-server-test-Pod: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'global.enabled=false' \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/standalone-server-test-Pod: disable with injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/standalone-server-test-Pod: image defaults to server.image.repository:tag" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=1.2.3' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]

  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=1.2.3' \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]
}

@test "server/standalone-server-test-Pod: image tag defaults to latest" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:latest" ]

  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.image.repository=foo' \
      --set 'server.image.tag=' \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:latest" ]
}

@test "server/standalone-server-test-Pod: default imagePullPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "IfNotPresent" ]
}

@test "server/standalone-server-test-Pod: Custom imagePullPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.image.pullPolicy=Always' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "Always" ]
}

@test "server/standalone-server-test-Pod: Custom imagePullSecrets" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'global.imagePullSecrets[0].name=foo' \
      --set 'global.imagePullSecrets[1].name=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.imagePullSecrets' | tee /dev/stderr)

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

@test "server/standalone-server-test-Pod: Custom imagePullSecrets - string array" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'global.imagePullSecrets[0]=foo' \
      --set 'global.imagePullSecrets[1]=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.imagePullSecrets' | tee /dev/stderr)

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

@test "server/standalone-server-test-Pod: default imagePullSecrets" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.imagePullSecrets' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

#--------------------------------------------------------------------
# resources

@test "server/standalone-server-test-Pod: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

#--------------------------------------------------------------------
# volumes

@test "server/standalone-server-test-Pod: server.volumes adds volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.volumes[0].name=plugins' \
      --set 'server.volumes[0].emptyDir=\{\}' \
      . | tee /dev/stderr |
      yq -r '.spec.volumes[] | select(.name == "plugins")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.emptyDir' | tee /dev/stderr)
  [ "${actual}" = "{}" ]
}

#--------------------------------------------------------------------
# volumeMounts

@test "server/standalone-server-test-Pod: server.volumeMounts adds volumeMount" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.volumeMounts[0].name=plugins' \
      --set 'server.volumeMounts[0].mountPath=/usr/local/libexec/vault' \
      --set 'server.volumeMounts[0].readOnly=true' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].volumeMounts[] | select(.name == "plugins")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/usr/local/libexec/vault" ]

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# log level

@test "server/standalone-server-test-Pod: default log level to empty" {
  cd `chart_dir`
  local objects=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $objects |
      yq -r 'map(select(.name=="VAULT_LOG_LEVEL")) | .[] .name' | tee /dev/stderr)
  [ "${value}" = "" ]
}

@test "server/standalone-server-test-Pod: log level can be changed" {
  cd `chart_dir`
  local objects=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set='server.logLevel=debug' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $objects |
      yq -r 'map(select(.name=="VAULT_LOG_LEVEL")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "debug" ]
}

#--------------------------------------------------------------------
# log format

@test "server/standalone-server-test-Pod: default log format to empty" {
  cd `chart_dir`
  local objects=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $objects |
      yq -r 'map(select(.name=="VAULT_LOG_FORMAT")) | .[] .name' | tee /dev/stderr)
  [ "${value}" = "" ]
}

@test "server/standalone-server-test-Pod: can set log format" {
  cd `chart_dir`
  local objects=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set='server.logFormat=json' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].env' | tee /dev/stderr)

  local value=$(echo $objects |
      yq -r 'map(select(.name=="VAULT_LOG_FORMAT")) | .[] .value' | tee /dev/stderr)
  [ "${value}" = "json" ]
}

#--------------------------------------------------------------------
# extraEnvironmentVars

@test "server/standalone-server-test-Pod: set extraEnvironmentVars" {
  cd `chart_dir`
  local object=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'server.extraEnvironmentVars.FOO=bar' \
      --set 'server.extraEnvironmentVars.FOOBAR=foobar' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].env' | tee /dev/stderr)

  local name=$(echo $object |
      yq -r 'map(select(.name=="FOO")) | .[] .value' | tee /dev/stderr)
  [ "${name}" = "bar" ]

  local name=$(echo $object |
      yq -r 'map(select(.name=="FOOBAR")) | .[] .value' | tee /dev/stderr)
  [ "${name}" = "foobar" ]

  local object=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'server.extraEnvironmentVars.FOO=bar' \
      --set 'server.extraEnvironmentVars.FOOBAR=foobar' \
      . | tee /dev/stderr |
      yq -r '.spec.containers[0].env' | tee /dev/stderr)

  local name=$(echo $object |
      yq -r 'map(select(.name=="FOO")) | .[] .value' | tee /dev/stderr)
  [ "${name}" = "bar" ]

  local name=$(echo $object |
      yq -r 'map(select(.name=="FOOBAR")) | .[] .value' | tee /dev/stderr)
  [ "${name}" = "foobar" ]
}

#--------------------------------------------------------------------
# Security Contexts
@test "server/standalone-server-test-Pod: uid default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "100" ]
}

@test "server/standalone-server-test-Pod: uid configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      --set 'server.uid=2000' \
      . | tee /dev/stderr |
      yq -r '.spec.securityContext.runAsUser' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

@test "server/standalone-server-test-Pod: gid default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "1000" ]
}

@test "server/standalone-server-test-Pod: gid configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      --set 'server.gid=2000' \
      . | tee /dev/stderr |
      yq -r '.spec.securityContext.runAsGroup' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

@test "server/standalone-server-test-Pod: fsgroup default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "1000" ]
}

@test "server/standalone-server-test-Pod: fsgroup configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      --set 'server.gid=2000' \
      . | tee /dev/stderr |
      yq -r '.spec.securityContext.fsGroup' | tee /dev/stderr)
  [ "${actual}" = "2000" ]
}

#--------------------------------------------------------------------
# annotations
@test "server/standalone-server-test-Pod: generic annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml \
      --set 'server.annotations=vaultIsAwesome: true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vaultIsAwesome"]' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

#--------------------------------------------------------------------
# OpenShift

@test "server/standalone-server-test-Pod: OpenShift - runAsUser disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.containers[0].securityContext.runAsUser | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/standalone-server-test-Pod: OpenShift - runAsGroup disabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/tests/server-test.yaml  \
      --set 'global.openshift=true' \
      . | tee /dev/stderr |
      yq '.spec.containers[0].securityContext.runAsGroup | length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
