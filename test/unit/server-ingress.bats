#!/usr/bin/env bats

load _helpers

@test "server/ingress: disabled by default" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-ingress.yaml  \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "server/ingress: checking host entry gets added and path is /" {
  cd `chart_dir`
  local actual=$(helm template \
      -x templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].host' | tee /dev/stderr)
  [ "${actual}" = 'test.com' ]

  local actual=$(helm template \
      -x templates/server-ingress.yaml \
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
      -x templates/server-ingress.yaml \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.hosts[0].host=test.com' \
      --set 'server.ingress.hosts[0].paths[0]=/' \
      . | tee /dev/stderr |
      yq  -r '.spec.rules[0].http.paths[0].backend.serviceName  | length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]

}
