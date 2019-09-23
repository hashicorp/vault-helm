#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Vault Server's Ingress

@test "server/ingress: server's general ingress config enabled" {
   cd `chart_dir`

   local actual=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'server.ingress.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.kind' | tee /dev/stderr)
   [ "${actual}" = "Ingress" ]

   local actual=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.nameTlsSecret=vault-tls-secret' \
      . | tee /dev/stderr |
      yq -r '.spec.tls[0].secretName' | tee /dev/stderr)
   [ "${actual}" = "vault-tls-secret" ]

   local actual=$(helm template \
      -x templates/server-ingress.yaml  \
      --set 'server.ingress.enabled=true' \
      --set 'server.ingress.wildcardTlsCerts=true' \
      . | tee /dev/stderr |
      yq '.spec.tls[0].secretName | match("vault-tls-secret") | length' | tee /dev/stderr)
   [ "${actual}" = "" ]
}
