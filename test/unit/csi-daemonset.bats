#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Daemonset

# Enabled
@test "csi/daemonset: created only when enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/csi-daemonset.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$( (helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "global.enabled=false" \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

# Image
@test "csi/daemonset: image is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.image.repository=SomeOtherImage" \
      --set "csi.image.tag=0.0.1" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].image' | tee /dev/stderr)
  [ "${actual}" = "SomeOtherImage:0.0.1" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.image.pullPolicy=SomePullPolicy" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].imagePullPolicy' | tee /dev/stderr)
  [ "${actual}" = "SomePullPolicy" ]
}

# Debug arg
@test "csi/daemonset: debug arg is configurable" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[1]' | tee /dev/stderr)
  [ "${actual}" = "--debug=false" ]

  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.debug=true" \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].args[1]' | tee /dev/stderr)
  [ "${actual}" = "--debug=true" ]
}

# updateStrategy
@test "csi/daemonset: updateStrategy is configurable" {
  cd `chart_dir`
  # Default
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "RollingUpdate" ]

  # OnDelete
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.daemonSet.updateStrategy.type=OnDelete" \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.type' | tee /dev/stderr)
  [ "${actual}" = "OnDelete" ]

  # Max unavailable
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set "csi.enabled=true" \
      --set "csi.daemonSet.updateStrategy.maxUnavailable=25%" \
      . | tee /dev/stderr |
      yq -r '.spec.updateStrategy.rollingUpdate.maxUnavailable' | tee /dev/stderr)
  [ "${actual}" = "25%" ]
}

#--------------------------------------------------------------------
# Extra annotations
@test "csi/daemonset: default csi.daemonSet.annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: specify csi.daemonSet.annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.daemonSet.annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.daemonSet.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: default csi.pod.annotations" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "csi/daemonset: specify csi.pod.annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.pod.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "csi/daemonset: specify csi.pod.annotations yaml string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/csi-daemonset.yaml \
      --set 'csi.enabled=true' \
      --set 'csi.pod.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.spec.template.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

#--------------------------------------------------------------------
# extraVolumes

@test "csi/daemonset: csi.extraVolumes adds extra volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.extraVolumes[0].type=configMap' \
      --set 'csi.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.configMap.name' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(echo $object |
      yq -r '.configMap.secretName' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.extraVolumes[0].type=configMap' \
      --set 'csi.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/vault/userconfig/foo" ]
}

@test "csi/daemonset: csi.extraVolumes adds extra secret volume" {
  cd `chart_dir`

  # Test that it defines it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.extraVolumes[0].type=secret' \
      --set 'csi.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.volumes[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.secret.name' | tee /dev/stderr)
  [ "${actual}" = "null" ]

  local actual=$(echo $object |
      yq -r '.secret.secretName' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  # Test that it mounts it
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.extraVolumes[0].type=configMap' \
      --set 'csi.extraVolumes[0].name=foo' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.name == "userconfig-foo")' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.readOnly' | tee /dev/stderr)
  [ "${actual}" = "true" ]

  local actual=$(echo $object |
      yq -r '.mountPath' | tee /dev/stderr)
  [ "${actual}" = "/vault/userconfig/foo" ]
}

#--------------------------------------------------------------------
# Readiness/liveness probes

@test "csi/daemonset: csi.livenessProbe is configurable" {
  cd `chart_dir`

  # Test the defaults
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "2" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "1" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  # Test it is configurable
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.livenessProbe.failureThreshold=10' \
      --set 'csi.livenessProbe.initialDelaySeconds=11' \
      --set 'csi.livenessProbe.periodSeconds=12' \
      --set 'csi.livenessProbe.successThreshold=13' \
      --set 'csi.livenessProbe.timeoutSeconds=14' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].livenessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "10" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "11" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "12" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "13" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "14" ]
}

@test "csi/daemonset: csi.readinessProbe is configurable" {
  cd `chart_dir`

  # Test the defaults
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "2" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "5" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "1" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "3" ]

  # Test it is configurable
  local object=$(helm template \
      --show-only templates/csi-daemonset.yaml  \
      --set 'csi.enabled=true' \
      --set 'csi.readinessProbe.failureThreshold=10' \
      --set 'csi.readinessProbe.initialDelaySeconds=11' \
      --set 'csi.readinessProbe.periodSeconds=12' \
      --set 'csi.readinessProbe.successThreshold=13' \
      --set 'csi.readinessProbe.timeoutSeconds=14' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].readinessProbe' | tee /dev/stderr)

  local actual=$(echo $object |
      yq -r '.failureThreshold' | tee /dev/stderr)
  [ "${actual}" = "10" ]
  local actual=$(echo $object |
      yq -r '.initialDelaySeconds' | tee /dev/stderr)
  [ "${actual}" = "11" ]
  local actual=$(echo $object |
      yq -r '.periodSeconds' | tee /dev/stderr)
  [ "${actual}" = "12" ]
  local actual=$(echo $object |
      yq -r '.successThreshold' | tee /dev/stderr)
  [ "${actual}" = "13" ]
  local actual=$(echo $object |
      yq -r '.timeoutSeconds' | tee /dev/stderr)
  [ "${actual}" = "14" ]
}
