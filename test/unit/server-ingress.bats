#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Vault Server's Ingress

@test "server/ingress: server's nginx ingress config enabled" {
   cd `chart_dir`
   local object=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.useNginx.enabled=true' \
      --set 'server.ingress.useNginx.sslPassthrough=true' \
      --set 'server.ingress.useNginx.useSslRedirect=true' \
      --set 'server.ingress.useNginx.useForwardedHeaders=true' \
      . | tee /dev/stderr |
      yq '.metadata.annotations' | tee /dev/stderr)

   local actual=$(echo $object |
      yq '["kubernetes.io/ingress.class"] | match("nginx")' | tee /dev/stderr)
   [ -z "${actual}" ]

   local actual=$(echo $object |
      yq '["nginx.ingress.kubernetes.io/use-forwarded-headers"] | match("true")' | tee /dev/stderr)
   [ -z "${actual}" ]

   local actual=$(echo $object |
      yq '["nginx.ingress.kubernetes.io/ssl-redirect"] | match("true")' | tee /dev/stderr)
   [ -z "${actual}" ]

   local actual=$(echo $object |
      yq '["nginx.ingress.kubernetes.io/ssl-passthrough"] | match("true")' | tee /dev/stderr)
   [ -z "${actual}" ]

   local actual=$(echo $object |
      yq '["nginx.ingress.kubernetes.io/use-forwarded-headers"] | match("true")' | tee /dev/stderr)
   [ -z "${actual}" ]
}

@test "server/ingress: server's general ingress config enabled" {
   cd `chart_dir`
   local actual=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'global.tlsDisable=false' \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.nameTlsSecret=vault-tls-secret' \
      . | tee /dev/stderr |
      yq -r '.spec.tls[0].secretName' | tee /dev/stderr)
   [ "${actual}" = "vault-tls-secret" ]

   local actual=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'global.tlsDisable=false' \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.useWildcardTlsCerts=true' \
      --set 'server.ingress.nameTlsSecret=vault-tls-secret' \
      . | tee /dev/stderr |
      yq '.spec.tls[0].secretName | match("vault-tls-secret") | length' | tee /dev/stderr)
   [ "${actual}" = "" ]
}
