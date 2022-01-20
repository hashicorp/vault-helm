#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Deployment

@test "injector/deployment: replica count" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-deployment.yaml \
      --set "injector.replicas=2" \
      . | tee /dev/stderr |
      yq '.spec.replicas' | tee /dev/stderr)
  [ "${actual}" = "2" ]
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
