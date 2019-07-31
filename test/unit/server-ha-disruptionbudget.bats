#!/usr/bin/env bats

load _helpers

@test "server/DisruptionBudget: enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/DisruptionBudget: disable with server.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-disruptionbudget.yaml  \
      --set 'globa.enabled=false' \
      --set 'server.ha.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: disable with server.disruptionBudget.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-disruptionbudget.yaml  \
      --set 'server.ha.disruptionBudget.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: disable with global.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-disruptionbudget.yaml  \
      --set 'global.enabled=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/DisruptionBudget: correct maxUnavailable with n=3" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-disruptionbudget.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.replicas=3' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "0" ]
}
