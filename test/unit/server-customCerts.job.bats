#!/usr/bin/env bats

load _helpers

#--------------------------------------------------------------------
# Custom TLS Certs Auto-Generation

@test "server/customCerts.job: tls enabled with generation of custom tls certs" {
  cd `chart_dir`
  local object=$(helm template \
      -x templates/server-customCerts.job.yaml  \
      --set 'global.tls.enabled=true' \
      --set 'global.tls.nameTlsSecret=vault-tls-secret' \
      --set 'global.tls.certParams.generateCustomCerts.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)

  local actual=$(echo $object |
     yq -r '.[6].name' | tee /dev/stderr)
  [ "${actual}" = "K8S_SECRET_NAME" ]

  local actual=$(echo $object |
     yq -r '.[6].value' | tee /dev/stderr)
  [ "${actual}" = "vault-tls-secret" ]
}
