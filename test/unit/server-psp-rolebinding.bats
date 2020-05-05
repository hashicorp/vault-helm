#!/usr/bin/env bats

load _helpers

@test "server/PSP-RoleBinding: PSP-RoleBinding not enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-RoleBinding: PSP-RoleBinding can be enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp-rolebinding.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PSP-RoleBinding: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-RoleBinding: disable with global.pspEnable false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PSP-RoleBinding: disable with global.enabled false global.pspEnable.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp-rolebinding.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
