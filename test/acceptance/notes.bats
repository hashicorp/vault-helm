#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Redundancy Zones Warning

@test "Notes: redundancy zones: warns when enabled without topologySpreadConstraints" {
  skip_if_k8s_version_lt "1.35"

  cd `chart_dir`
  local result=$(helm install test . \
      --dry-run \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.ha.raft.redundancyZones.enabled=true' \
      --set-string 'server.ha.raft.config=storage "raft" { path = "/vault/data" autopilot_redundancy_zone = "VAULT_REDUNDANCY_ZONE" } service_registration "kubernetes" {}' \
      2>&1 | tee /dev/stderr)

  [[ "${result}" == *"WARNING: Redundancy Zones Enabled Without topologySpreadConstraints"* ]]
  [[ "${result}" == *"server.ha.raft.redundancyZones.enabled=true"* ]]
  [[ "${result}" == *"topologySpreadConstraints"* ]]
}

@test "Notes: redundancy zones: no warning when enabled with topologySpreadConstraints" {
  skip_if_k8s_version_lt "1.35"

  cd `chart_dir`
  local result=$(helm install test . \
      --dry-run \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.ha.raft.redundancyZones.enabled=true' \
      --set 'server.topologySpreadConstraints[0].maxSkew=1' \
      --set 'server.topologySpreadConstraints[0].topologyKey=topology.kubernetes.io/zone' \
      --set 'server.topologySpreadConstraints[0].whenUnsatisfiable=DoNotSchedule' \
      --set-string 'server.ha.raft.config=storage "raft" { path = "/vault/data" autopilot_redundancy_zone = "VAULT_REDUNDANCY_ZONE" } service_registration "kubernetes" {}' \
      2>&1 | tee /dev/stderr)

  [[ "${result}" != *"WARNING: Redundancy Zones Enabled Without topologySpreadConstraints"* ]]
}

@test "Notes: redundancy zones: no warning when disabled" {
  skip_if_k8s_version_lt "1.35"

  cd `chart_dir`
  local result=$(helm install test . \
      --dry-run \
      --set 'server.ha.enabled=true' \
      --set 'server.ha.raft.enabled=true' \
      --set 'server.ha.raft.redundancyZones.enabled=false' \
      2>&1 | tee /dev/stderr)

  [[ "${result}" != *"WARNING: Redundancy Zones Enabled Without topologySpreadConstraints"* ]]
}
