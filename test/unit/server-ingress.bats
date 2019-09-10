#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Custom TLS Certs Auto-Generation

@test "server/ingress: server's ingress enabled and tls disabled" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.useNginx.enabled=true' \
      --set 'server.ingress.useNginx.sslPassthrough=true' \
      --set 'server.ingress.useNginx.useSslRedirect=true' \
      . | tee /dev/stderr |
      yq -r '.metadata.annotations' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = "kubernetes.io/ingress.class" ]

  local actual=$(echo $object |
     yq -r '.[0].value' | tee /dev/stderr)
  [ "${actual}" = "nginx" ]
}



@test "server/ingress: server's ingress enabled and tls enabled" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'global.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.nameTlsSecret=vault-tls-secret' \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.useNginx.enabled=true' \
      --set 'server.ingress.useNginx.sslPassthrough=true' \
      --set 'server.ingress.useNginx.useSslRedirect=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[6].name' | tee /dev/stderr)
  [ "${actual}" = "K8S_SECRET_NAME" ]

  local actual=$(echo $object |
     yq -r '.[6].value' | tee /dev/stderr)
  [ "${actual}" = "vault-tls-secret" ]
}
@test "server/ingress: server's nginx ingress enabled and tls disabled" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'global.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.nameTlsSecret=vault-tls-secret' \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.useNginx.enabled=true' \
      --set 'server.ingress.useNginx.sslPassthrough=true' \
      --set 'server.ingress.useNginx.useSslRedirect=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[6].name' | tee /dev/stderr)
  [ "${actual}" = "K8S_SECRET_NAME" ]

  local actual=$(echo $object |
     yq -r '.[6].value' | tee /dev/stderr)
  [ "${actual}" = "vault-tls-secret" ]
}
@test "server/ingress: server's nginx ingress and tls enabled" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'global.enabled=true' \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.nameTlsSecret=vault-tls-secret' \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.useNginx.enabled=true' \
      --set 'server.ingress.useNginx.sslPassthrough=true' \
      --set 'server.ingress.useNginx.useSslRedirect=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[6].name' | tee /dev/stderr)
  [ "${actual}" = "K8S_SECRET_NAME" ]

  local actual=$(echo $object |
     yq -r '.[6].value' | tee /dev/stderr)
  [ "${actual}" = "vault-tls-secret" ]
}
