#!/usr/bin/env bats

load _helpers

@test "server/route: OpenShift - disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --set 'global.openshift=true' \
      --show-only templates/server-route.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/route: OpenShift -disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-route.yaml  \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/route: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-route.yaml  \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]
  local actual=$(helm template \
      --show-only templates/server-route.yaml  \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "server/route: OpenShift - checking host entry gets added and path is /" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.host=test.com' \
      . | tee /dev/stderr |
      yq  -r '.spec.host' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]
}

@test "server/route: OpenShift - vault backend should be added when I specify a path" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.host=test.com' \
      . | tee /dev/stderr |
      yq  -r '.spec.to.name  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}

@test "server/route: OpenShift - labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.labels.traffic=external' \
      --set 'server.route.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "server/route: OpenShift - annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.annotations=kubernetes.io/route.class: haproxy' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/route.class"]' | tee /dev/stderr)
  [ "${actual}" = "haproxy" ]
}

@test "server/route: OpenShift - annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set server.route.annotations."kubernetes\.io/route\.class"=haproxy \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/route.class"]' | tee /dev/stderr)
  [ "${actual}" = "haproxy" ]
}

@test "server/route: OpenShift - route points to main service by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.to.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

@test "server/route: OpenShift - route points to main service when not ha and activeService is true" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.activeService=true' \
      . | tee /dev/stderr |
      yq -r '.spec.to.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

@test "server/route: OpenShift - route points to active service by when HA by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.to.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-active" ]
}

@test "server/route: OpenShift - route points to general service by when HA when configured" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.activeService=false' \
      --set 'server.ha.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.to.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault" ]
}

@test "server/route: OpenShift - route termination mode set to default passthrough" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.tls.termination' | tee /dev/stderr)
  [ "${actual}" = "passthrough" ]
}

@test "server/route: OpenShift - route termination mode set to edge" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.tls.termination=edge' \
      . | tee /dev/stderr |
      yq -r '.spec.tls.termination' | tee /dev/stderr)
  [ "${actual}" = "edge" ]
}

@test "server/route: OpenShift - route custom tls entry" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-route.yaml \
      --set 'global.openshift=true' \
      --set 'server.route.enabled=true' \
      --set 'server.route.tls.insecureEdgeTerminationPolicy=Redirect' \
      . | tee /dev/stderr |
      yq -r '.spec.tls.insecureEdgeTerminationPolicy' | tee /dev/stderr)
  [ "${actual}" = "Redirect" ]
}
