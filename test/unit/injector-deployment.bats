#!/usr/bin/env bats

load _helpers

@test "injector/deployment: default injector.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: enable with injector.enabled true" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/deployment: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'global.enabled=false' \
      --set 'injector.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/deployment: image defaults to injector.image" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'injector.image.repository=foo' \
      --set 'injector.image.tag=1.2.3' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]

  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'injector.image.repository=foo' \
      --set 'injector.image.tag=1.2.3' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "foo:1.2.3" ]
}

@test "injector/deployment: default imagePullPolicy" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "IfNotPresent" ]
}

@test "injector/deployment: default resources" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "injector/deployment: custom resources" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.resources.requests.memory=256Mi' \
      --set 'injector.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'injector.enabled=true' \
      --set 'injector.resources.limits.memory=256Mi' \
      --set 'injector.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.memory' | tee /dev/stderr)
  [ "${actual}" = "256Mi" ]

  local actual=$(helm template \
      -x templates/injector-deployment.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.resources.requests.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.requests.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]

  local actual=$(helm template \
      -x templates/injector-deployment.yaml \
      --set 'injector.enabled=true' \
      --set 'injector.resources.limits.cpu=250m' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].resources.limits.cpu' | tee /dev/stderr)
  [ "${actual}" = "250m" ]
}

@test "injector/deployment: manual TLS environment vars" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/injector-deployment.yaml  \
      --set 'injector.certs.secretName=foobar' \
      --set 'injector.certs.certName=test.crt' \
      --set 'injector.certs.keyName=test.key' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[4].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_CERT_FILE" ]

  local actual=$(echo $object |
      yq -r '.[4].value' | tee /dev/stderr)
  [ "${actual}" = "/etc/webhook/certs/test.crt" ]

  local actual=$(echo $object |
      yq -r '.[5].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_KEY_FILE" ]

  local actual=$(echo $object |
      yq -r '.[5].value' | tee /dev/stderr)
  [ "${actual}" = "/etc/webhook/certs/test.key" ]
}

@test "injector/deployment: auto TLS by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts | length' | tee /dev/stderr)
  [ "${actual}" = "0" ]

  local object=$(helm template \
      -x templates/injector-deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[4].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_TLS_AUTO" ]

  local actual=$(echo $object |
      yq -r '.[5].name' | tee /dev/stderr)
  [ "${actual}" = "AGENT_INJECT_TLS_AUTO_HOSTS" ]
}
