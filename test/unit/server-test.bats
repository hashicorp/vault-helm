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
