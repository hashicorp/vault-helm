#!/usr/bin/env bats

load _helpers

@test "global rbac: disabled by global.rbac" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-clusterrole.yaml \
      --show-only templates/csi-clusterrolebinding.yaml \
      --show-only templates/injector-clusterrole.yaml \
      --show-only templates/injector-clusterrolebinding.yaml \
      --show-only templates/injector-psp-role.yaml \
      --show-only templates/injector-psp-rolebinding.yaml \
      --show-only templates/injector-role.yaml \
      --show-only templates/injector-rolebinding.yaml \
      --show-only templates/server-clusterrolebinding.yaml \
      --show-only templates/server-discovery-role.yaml \
      --show-only templates/server-discovery-rolebinding.yaml \
      --show-only templates/server-psp-role.yaml \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'global.rbac=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
