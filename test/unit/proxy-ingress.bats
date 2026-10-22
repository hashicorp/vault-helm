#!/usr/bin/env bats

load _helpers

@test "proxy/Ingress: disabled by default" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-ingress.yaml \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Ingress: disabled when proxy.enabled=true but ingress.enabled=false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Ingress: disabled when ingress.enabled=true but proxy.enabled=false" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.ingress.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Ingress: enabled with proxy.enabled and ingress.enabled" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "true" ]
}

@test "proxy/Ingress: disabled when the proxy Service is disabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.service.enabled=false' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Ingress: not governed by global.enabled" {
  cd `chart_dir`
  local actual=$( (helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'global.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . || echo "---") | tee /dev/stderr |
      yq 'length > 0' | tee /dev/stderr)
  [ "${actual}" = "false" ]
}

@test "proxy/Ingress: name is <release>-proxy" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-proxy" ]
}

@test "proxy/Ingress: namespace" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "foo" ]

  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'global.namespace=bar' \
      --namespace foo \
      . | tee /dev/stderr |
      yq -r '.metadata.namespace' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/Ingress: backend is the proxy Service on proxy.service.port" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr)

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = "release-name-vault-proxy" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[0].backend.service.port.number' | tee /dev/stderr)
  [ "${actual}" = "8100" ]
}

@test "proxy/Ingress: backend port follows proxy.service.port" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.service.port=9100' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].backend.service.port.number' | tee /dev/stderr)
  [ "${actual}" = "9100" ]
}

@test "proxy/Ingress: host entry gets added and path defaults to /" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.hosts[0].host=proxy.example.com' \
      . | tee /dev/stderr)

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].host' | tee /dev/stderr)
  [ "${actual}" = "proxy.example.com" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[0].path' | tee /dev/stderr)
  [ "${actual}" = "/" ]
}

@test "proxy/Ingress: multiple hosts and paths" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.hosts[0].host=proxy.example.com' \
      --set 'proxy.ingress.hosts[0].paths[0]=/v1' \
      --set 'proxy.ingress.hosts[1].host=proxy2.example.com' \
      --set 'proxy.ingress.hosts[1].paths[0]=/v1/secret' \
      . | tee /dev/stderr)

  local actual=$(echo "$output" |
      yq -r '.spec.rules | length' | tee /dev/stderr)
  [ "${actual}" = "2" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[0].path' | tee /dev/stderr)
  [ "${actual}" = "/v1" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[1].host' | tee /dev/stderr)
  [ "${actual}" = "proxy2.example.com" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[1].http.paths[0].path' | tee /dev/stderr)
  [ "${actual}" = "/v1/secret" ]
}

@test "proxy/Ingress: extra paths prepend host configuration" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.hosts[0].host=proxy.example.com' \
      --set 'proxy.ingress.hosts[0].paths[0]=/' \
      --set 'proxy.ingress.extraPaths[0].path=/annotation-service' \
      --set 'proxy.ingress.extraPaths[0].backend.service.name=ssl-redirect' \
      . | tee /dev/stderr)

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[0].backend.service.name' | tee /dev/stderr)
  [ "${actual}" = "ssl-redirect" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[0].path' | tee /dev/stderr)
  [ "${actual}" = "/annotation-service" ]

  local actual=$(echo "$output" |
      yq -r '.spec.rules[0].http.paths[1].path' | tee /dev/stderr)
  [ "${actual}" = "/" ]
}

@test "proxy/Ingress: default pathType is Prefix" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].pathType' | tee /dev/stderr)
  [ "${actual}" = "Prefix" ]
}

@test "proxy/Ingress: custom pathType" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.pathType=ImplementationSpecific' \
      . | tee /dev/stderr |
      yq -r '.spec.rules[0].http.paths[0].pathType' | tee /dev/stderr)
  [ "${actual}" = "ImplementationSpecific" ]
}

@test "proxy/Ingress: no ingressClassName by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.ingressClassName' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/Ingress: ingressClassName added to spec" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.ingressClassName=nginx' \
      . | tee /dev/stderr |
      yq -r '.spec.ingressClassName' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}

@test "proxy/Ingress: no tls by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.tls' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/Ingress: tls added to spec" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.tls[0].secretName=proxy-tls' \
      --set 'proxy.ingress.tls[0].hosts[0]=proxy.example.com' \
      . | tee /dev/stderr)

  local actual=$(echo "$output" |
      yq -r '.spec.tls[0].secretName' | tee /dev/stderr)
  [ "${actual}" = "proxy-tls" ]

  local actual=$(echo "$output" |
      yq -r '.spec.tls[0].hosts[0]' | tee /dev/stderr)
  [ "${actual}" = "proxy.example.com" ]
}

@test "proxy/Ingress: default labels" {
  cd `chart_dir`
  local output=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr)

  local actual=$(echo "$output" |
      yq -r '.metadata.labels["app.kubernetes.io/name"]' | tee /dev/stderr)
  [ "${actual}" = "vault-proxy" ]

  local actual=$(echo "$output" |
      yq -r '.metadata.labels["app.kubernetes.io/instance"]' | tee /dev/stderr)
  [ "${actual}" = "release-name" ]
}

@test "proxy/Ingress: extra labels get added" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.labels.traffic=external' \
      . | tee /dev/stderr |
      yq -r '.metadata.labels.traffic' | tee /dev/stderr)
  [ "${actual}" = "external" ]
}

@test "proxy/Ingress: no annotations by default" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)
  [ "${actual}" = "null" ]
}

@test "proxy/Ingress: specify annotations yaml" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.annotations.foo=bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}

@test "proxy/Ingress: specify annotations string" {
  cd `chart_dir`
  local actual=$(helm template \
      --show-only templates/proxy-ingress.yaml \
      --set 'proxy.enabled=true' \
      --set 'proxy.ingress.enabled=true' \
      --set 'proxy.ingress.annotations=foo: bar' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations.foo' | tee /dev/stderr)
  [ "${actual}" = "bar" ]
}
