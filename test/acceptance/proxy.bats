#!/usr/bin/env bats

load _helpers

@test "proxy: testing deployment" {
  cd "$(chart_dir)"
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  echo "Using chart vars: ${SET_CHART_VALUES}"

  eval "${PRE_CHART_CMDS}"
  # The injector is not needed here; leaving it enabled also breaks the
  # helm upgrade below, because the injector patches the mutating webhook's
  # caBundle at runtime and server-side apply refuses to upgrade over the
  # resulting field-ownership conflict.
  helm install "$(name_prefix)" . \
    --set='server.dev.enabled=true' \
    --set='injector.enabled=false' \
    --set='proxy.enabled=true' \
    --set='proxy.logLevel=debug' \
    ${SET_CHART_VALUES}
  check_vault_versions "$(name_prefix)"
  wait_for_running "$(name_prefix)-0"
  wait_for_ready "$(kubectl get pod -l component=proxy -o jsonpath='{.items[0].metadata.name}')"

  # Replicas
  local replicas=$(kubectl get deployment "$(name_prefix)-proxy" --output json |
    jq -r '.spec.replicas')
  [ "${replicas}" == "1" ]

  # Probes default to TCP socket checks on the listener port: an HTTP probe
  # would forward to Vault, so a Vault outage would restart the proxy and
  # destroy its cache, the one thing still serving requests during an outage
  local liveness=$(kubectl get deployment "$(name_prefix)-proxy" --output json |
    jq -r '.spec.template.spec.containers[0].livenessProbe.tcpSocket.port')
  [ "${liveness}" == "8100" ]

  local readiness=$(kubectl get deployment "$(name_prefix)-proxy" --output json |
    jq -r '.spec.template.spec.containers[0].readinessProbe.tcpSocket.port')
  [ "${readiness}" == "8100" ]

  # Config checksum pod annotation
  local checksum=$(kubectl get deployment "$(name_prefix)-proxy" --output json |
    jq -r '.spec.template.metadata.annotations["vault.hashicorp.com/config-checksum"]')
  [ "${checksum}" != "null" ]

  # Service
  local service=$(kubectl get service "$(name_prefix)-proxy" --output json |
    jq -r '.spec.type')
  [ "${service}" == "ClusterIP" ]

  local port=$(kubectl get service "$(name_prefix)-proxy" --output json |
    jq -r '.spec.ports[0].port')
  [ "${port}" == "8100" ]

  # Provision a test user, policy and secret on the dev server
  kubectl exec "$(name_prefix)-0" -- sh -c '
    export VAULT_TOKEN=root VAULT_ADDR=http://127.0.0.1:8200
    vault auth enable userpass
    echo "path \"secret/data/*\" { capabilities = [\"read\"] }" | vault policy write proxy-acceptance -
    vault write auth/userpass/users/proxy-acceptance password=testpassword policies=proxy-acceptance'

  # Pass-through: write and read a KV secret through the proxy service
  kubectl exec "$(name_prefix)-0" -- sh -c "
    export VAULT_TOKEN=root VAULT_ADDR=http://$(name_prefix)-proxy:8100
    vault kv put secret/proxy-acceptance message=proxy-pass-through"

  local passthrough=$(kubectl exec "$(name_prefix)-0" -- sh -c "
    export VAULT_TOKEN=root VAULT_ADDR=http://$(name_prefix)-proxy:8100
    vault kv get -field=message secret/proxy-acceptance")
  [ "${passthrough}" == "proxy-pass-through" ]

  # Caching: identical login requests are served from the cache, so the
  # second login must return the same token rather than a new one. The cache
  # index includes the client token, so both requests must come from the same
  # client: vault-0's CLI silently attaches the dev root token from
  # ~/.vault-token.
  local token1=$(kubectl exec "$(name_prefix)-0" -- sh -c "
    VAULT_ADDR=http://$(name_prefix)-proxy:8100 vault write -field=token auth/userpass/login/proxy-acceptance password=testpassword")
  local token2=$(kubectl exec "$(name_prefix)-0" -- sh -c "
    VAULT_ADDR=http://$(name_prefix)-proxy:8100 vault write -field=token auth/userpass/login/proxy-acceptance password=testpassword")
  [ -n "${token1}" ]
  [ "${token1}" == "${token2}" ]

  kubectl logs deployment/"$(name_prefix)-proxy" | grep -q "returning cached dynamic secret response"

  # Auto-auth: configure the Kubernetes auth method with a role bound to the
  # proxy's service account. The chart's ClusterRoleBinding already grants the
  # server's service account the TokenReview permission this requires.
  kubectl exec "$(name_prefix)-0" -- sh -c "
    export VAULT_TOKEN=root VAULT_ADDR=http://127.0.0.1:8200
    vault auth enable kubernetes
    vault write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc
    vault write auth/kubernetes/role/vault-proxy \
      bound_service_account_names=$(name_prefix)-proxy \
      bound_service_account_namespaces=acceptance \
      policies=proxy-acceptance ttl=10m"

  # Switch proxy.config to the auto_auth/api_proxy example shipped in
  # values.yaml. This must roll the deployment via the config-checksum
  # pod annotation.
  local checksum_before=$(kubectl get deployment "$(name_prefix)-proxy" --output json |
    jq -r '.spec.template.metadata.annotations["vault.hashicorp.com/config-checksum"]')

  cat <<'EOF' > "${BATS_TEST_TMPDIR}/proxy-auto-auth-values.yaml"
proxy:
  config: |
    vault {
      address = "{{ include "proxy.vaultAddress" . }}"
      retry {
        num_retries = 5
      }
    }

    listener "tcp" {
      address = "[::]:8100"
      tls_disable = true
    }

    auto_auth {
      method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
          role = "vault-proxy"
        }
      }
    }

    api_proxy {
      use_auto_auth_token = true
    }

    cache {
    }
EOF
  helm upgrade "$(name_prefix)" . --reuse-values \
    -f "${BATS_TEST_TMPDIR}/proxy-auto-auth-values.yaml"
  kubectl rollout status deployment "$(name_prefix)-proxy" --timeout=2m

  local checksum_after=$(kubectl get deployment "$(name_prefix)-proxy" --output json |
    jq -r '.spec.template.metadata.annotations["vault.hashicorp.com/config-checksum"]')
  [ "${checksum_after}" != "null" ]
  [ "${checksum_before}" != "${checksum_after}" ]

  # A tokenless request through the proxy succeeds: the proxy attaches its
  # auto-auth token on behalf of the client. Retry briefly to allow the fresh
  # pod's auth handler to complete its first login.
  local tokenless=""
  for _ in $(seq 15); do
    tokenless=$(kubectl exec "$(name_prefix)-0" -- \
      wget -qO- "http://$(name_prefix)-proxy:8100/v1/secret/data/proxy-acceptance" 2>/dev/null |
      jq -r '.data.data.message')
    if [ "${tokenless}" == "proxy-pass-through" ]; then
      break
    fi
    sleep 2
  done
  [ "${tokenless}" == "proxy-pass-through" ]
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm delete vault
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
      kubectl config unset contexts."$(kubectl config current-context)".namespace
  fi
}
