#!/usr/bin/env bats

load _helpers

@test "server/ingress: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-ingress.yaml  \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ingress: disable by injector.externalVaultAddr" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/server-ingress.yaml  \
      --set 'server.ingress.enabled=true' \
      --set 'injector.externalVaultAddr=http://vault-outside' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ingress: checking host entry gets added and path is /" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].host' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].http.paths[0].path' | tee /dev/stderr)
  [ "${actual}" = '/' ]
}

@test "server/ingress: vault backend should be added when I specify a path" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].http.paths[0].backend.service.name  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}

@test "server/ingress: extra paths prepend host configuration" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      --set 'server.ingress.extraPaths[0].path=/annotation-service' \
      --set 'server.ingress.extraPaths[0].backend.service.name=ssl-redirect' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = 'ssl-redirect' ]

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      --set 'server.ingress.extraPaths[0].path=/annotation-service' \
      --set 'server.ingress.extraPaths[0].backend.service.name=ssl-redirect' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].http.paths[0].path' | tee /dev/stderr)
  [ "${actual}" = '/annotation-service' ]

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      --set 'server.ingress.extraPaths[0].path=/annotation-service' \
      --set 'server.ingress.extraPaths[0].backend.service.name=ssl-redirect' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].http.paths[1].path' | tee /dev/stderr)
  [ "${actual}" = '/' ]
}

@test "server/ingress: labels gets added to object" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.labels.traffic=external' \
      --set 'server.ingress.labels.team=dev' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "server/ingress: annotations added to object - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.annotations=kubernetes.io/ingress.class: nginx' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/ingress: annotations added to object - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set server.ingress.annotations."kubernetes\.io/ingress\.class"=nginx \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations["kubernetes.io/ingress.class"]' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/ingress: ingressClassName added to object spec - string" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set server.ingress.ingressClassName=nginx \
      . | tee /dev/stderr |
      yq -r '.spec.ingressClassName' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "server/ingress: ingressClassName is not added by default" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ingressClassName' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ingress: uses active service when ha by default - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault-active" ]
}

@test "server/ingress: uses regular service when configured with ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.activeService=false' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=true' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault" ]
}

@test "server/ingress: uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault" ]
}

@test "server/ingress: k8s 1.18.3 uses regular service when not ha - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      --kube-version 1.18.3 \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].backend.serviceName' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault" ]
}

@test "server/ingress: uses regular service when not ha and activeService is true - yaml" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.activeService=true' \
      --set 'server.dev.enabled=false' \
      --set 'server.ha.enabled=false' \
      --set 'server.service.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = "RELEASE-NAME-vault" ]
}

@test "server/ingress: pathType is added to Kubernetes version == 1.19.0" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set server.ingress.pathType=ImplementationSpecific \
      --kube-version 1.19.0 \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].pathType' | tee /dev/stderr)
  [ "${actual}" = "ImplementationSpecific" ]
}

@test "server/ingress: pathType is not added to Kubernetes versions < 1.19" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set server.ingress.pathType=ImplementationSpecific \
      --kube-version 1.18.3 \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].pathType' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "server/ingress: pathType is added to Kubernetes versions > 1.19" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set server.ingress.pathType=Prefix \
      --kube-version 1.20.0 \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].pathType' | tee /dev/stderr)
  [ "${actual}" = "Prefix" ]
}
