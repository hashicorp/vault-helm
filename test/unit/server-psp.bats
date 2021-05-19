#!/usr/bin/env bats

load _helpers

@test "server/PodSecurityPolicy: PodSecurityPolicy not enabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy can be enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy annotations are templated correctly" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.metadata.annotations | length == 4' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.metadata.annotations | length == 4' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.metadata.annotations | length == 4' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: annotations are added - string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations=vault-is: amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations=vault-is: amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations=vault-is: amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]
}

@test "server/PodSecurityPolicy: annotations are added - object" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations.vault-is=amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations.vault-is=amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'global.psp.annotations.vault-is=amazing' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["vault-is"]' | tee /dev/stderr)
  [ "${actual}" = "amazing" ]
}

@test "server/PodSecurityPolicy: disable with global.enabled false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.enabled=false' \
      --set 'global.psp.enable=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: disable with global.psp.enable false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$( (helm template \
      --show-only templates/server-psp.yaml  \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy allows PVC by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy allows PVC with dataStorage" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'server.dataStorage.enabled=true' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "server/PodSecurityPolicy: PodSecurityPolicy does not allow PVC without dataStorage" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.dev.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.ha.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/server-psp.yaml \
      --set 'server.standalone.enabled=true' \
      --set 'global.psp.enable=true' \
      --set 'server.dataStorage.enabled=false' \
      . | tee /dev/stderr |
      yq '.spec.volumes | contains(["persistentVolumeClaim"])' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}
