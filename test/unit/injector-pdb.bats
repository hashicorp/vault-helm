#!/usr/bin/env bats

load _helpers

@test "injector/PDB: not enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-pdb.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PDB: enable with injector.pdb.create" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-pdb.yaml  \
      --set 'injector.pdb.create=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PDB: disable with global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/injector-pdb.yaml  \
      --set 'global.enabled=false' \
      --set 'injector.pdb.create=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "injector/PDB: can set minAvailable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-pdb.yaml  \
      --set 'injector.pdb.create=true' \
      --set 'injector.pdb.minAvailable=4' \
      . | tee /dev/stderr |
      yq '.spec.minAvailable == 4' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "injector/PDB: can set maxUnavailable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/injector-pdb.yaml  \
      --set 'injector.pdb.create=true' \
      --set 'injector.pdb.maxUnavailable=4' \
      . | tee /dev/stderr |
      yq '.spec.maxUnavailable == 4' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}
