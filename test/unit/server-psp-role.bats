#!/usr/bin/env bats

load _helpers

@test "server/PSP-Role: PSP-Role not enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-Role: PSP-Role can be enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp-role.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp-role.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp-role.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PSP-Role: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-Role: disable with global.psp.enable false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-role.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
