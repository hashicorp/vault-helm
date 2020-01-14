#!/usr/bin/env bats

load _helpers

@test "server/PodSecurityPolicy: PodSecurityPolicy not enabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy can be enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: disable with global.pspEnable false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=false' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: disable with global.enabled false global.pspEnable.enabled false" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy allows PVC by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy allows PVC with dataStorage" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy does not allow PVC without dataStorage" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.pspEnable=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.pspEnable=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      -x templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.pspEnable=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
