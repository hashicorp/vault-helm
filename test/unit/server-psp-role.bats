#!/usr/bin/env bats

load _helpers

@test "server/PSP-Role: PSP-Role not enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp-role.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-Role: PSP-Role can be enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp-role.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PSP-Role: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-Role: disable with global.pspEnable false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-Role: disable with global.enabled false global.pspEnable.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp-role.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
