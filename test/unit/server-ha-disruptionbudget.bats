#!/usr/bin/env bats

load _helpers

@test "server/DisruptionBudget: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/DisruptionBudget: disable with server.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'global.enabled=false' \
      --set 'server.ha.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: disable with server.disruptionBudget.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.disruptionBudget.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'global.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: disable with injector.exernalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/DisruptionBudget: correct maxUnavailable with n=1" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=1' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "0" ]
}

@test "server/DisruptionBudget: correct maxUnavailable with n=3" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=3' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "1" ]
}

@test "server/DisruptionBudget: correct maxUnavailable with n=5" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=5' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "server/DisruptionBudget: correct maxUnavailable with custom value" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=3' \
      --set 'server.ha.disruptionBudget.maxUnavailable=2' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "2" ]
}

@test "server/DisruptionBudget: apiVersion is set correctly >= version 1.21 of kube" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-disruptionbudget.yaml \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=1' \
      --kube-version 1.22.5 \
      . | tee /dev/stderr |
      yq '.apiVersion == "policy/v1"' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
