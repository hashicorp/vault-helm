#!/usr/bin/env bats

load _helpers

@test "connectInject/Deployment: disabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "connectInject/Deployment: enable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'global.enabled=false' \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "connectInject/Deployment: disable with connectInject.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "connectInject/Deployment: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "connectInject/Deployment: no secretName: no tls-{cert,key}-file set" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-cert-file"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-key-file"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-auto"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "connectInject/Deployment: with secretName: tls-{cert,key}-file set" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.certs.secretName=foo' \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-cert-file"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.certs.secretName=foo' \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-key-file"))' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/connect-inject-deployment.yaml  \
      --set 'connectInject.certs.secretName=foo' \
      --set 'connectInject.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers[0].command | any(contains("-tls-auto"))' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
