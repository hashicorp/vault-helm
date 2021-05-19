#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Deployment

@test "injector/deployment: leader elector replica count" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "injector/deployment: leader elector - sidecar is created only when enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.enabled=false" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "1" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq '.spec.template.spec.containers | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "injector/deployment: leader elector image name is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.image.repository=SomeOtherImage" \
      --set "injector.leaderElector.image.tag=SomeOtherTag" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].image' | tee /dev/stderr)
  [ "${actual}" = "SomeOtherImage:SomeOtherTag" ]
}

@test "injector/deployment: leader elector configuration for sidecar-injector" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[] | select(.name == "AGENT_INJECT_USE_LEADER_ELECTOR") | .value' | tee /dev/stderr)
  [ "${actual}" = "" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[] | select(.name == "AGENT_INJECT_USE_LEADER_ELECTOR") | .value' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[] | select(.name == "NAMESPACE") | .valueFrom.fieldRef.fieldPath' | tee /dev/stderr)
  [ "${actual}" = "" ]

  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env[] | select(.name == "NAMESPACE") | .valueFrom.fieldRef.fieldPath' | tee /dev/stderr)
  [ "${actual}" = "metadata.namespace" ]
}

@test "injector/deployment: leader elector TTL is configurable" {
  cd `chart_dir`
  # Default value 60s
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].args[3]' | tee /dev/stderr)
  [ "${actual}" = "--ttl=60s" ]

  # Configured to 30s
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.ttl=30s" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[1].args[3]' | tee /dev/stderr)
  [ "${actual}" = "--ttl=30s" ]
}

#--------------------------------------------------------------------
# Resource creation

@test "injector/certs-secret: created/skipped as appropriate" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-certs-secret.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-certs-secret.yaml \
      --set "injector.replicas=2" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-certs-secret.yaml \
      --set "injector.replicas=2" \
      --set "injector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-certs-secret.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-certs-secret.yaml \
      --set "injector.replicas=2" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/leader-endpoint: created/skipped as appropriate" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-leader-endpoint.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-leader-endpoint.yaml \
      --set "injector.replicas=2" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-leader-endpoint.yaml \
      --set "injector.replicas=2" \
      --set "injector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-leader-endpoint.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-leader-endpoint.yaml \
      --set "injector.replicas=2" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/role: created/skipped as appropriate" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-role.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-role.yaml \
      --set "injector.replicas=2" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-role.yaml \
      --set "injector.replicas=2" \
      --set "injector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-role.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-role.yaml \
      --set "injector.replicas=2" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/rolebinding: created/skipped as appropriate" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-rolebinding.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-rolebinding.yaml \
      --set "injector.replicas=2" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-rolebinding.yaml \
      --set "injector.replicas=2" \
      --set "injector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-rolebinding.yaml \
      --set "injector.replicas=2" \
      --set "injector.leaderElector.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/injector-rolebinding.yaml \
      --set "injector.replicas=2" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}