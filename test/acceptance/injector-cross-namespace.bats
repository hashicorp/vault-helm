#!/usr/bin/env bats

load _helpers

setup() {
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance
  kubectl create secret generic vault-license --from-literal license=$VAULT_LICENSE_CI
}

teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm delete vault
      kubectl delete --all pvc
      kubectl delete secret test
      kubectl delete namespace acceptance
  fi
}

@test "injector/enterprise: testing cross namespace access" {
  cd `chart_dir`

  kubectl create secret generic test \
    --from-file ./test/acceptance/injector-test/bootstrap-cross-namespace.sh

  kubectl label secret test app=vault-agent-demo

  helm install "$(name_prefix)" \
    --set='server.image.repository=hashicorp/vault-enterprise' \
    --set="server.image.tag=$(yq -r '.server.image.tag' values.yaml)-ent" \
    --set="server.extraVolumes[0].type=secret" \
    --set="server.extraVolumes[0].name=test" \
    --set='server.ha.enabled=true' \
    --set='server.ha.raft.enabled=true' \
    --set='server.ha.replicas=1' \
    --set='server.enterpriseLicense.secretName=vault-license' .
  wait_for_running "$(name_prefix)-0"

  wait_for_ready $(kubectl get pod -l component=webhook -o jsonpath="{.items[0].metadata.name}")

  kubectl exec -ti "$(name_prefix)-0" -- /bin/sh -c "cp /vault/userconfig/test/bootstrap-cross-namespace.sh /tmp/bootstrap.sh && chmod +x /tmp/bootstrap.sh && /tmp/bootstrap.sh"
  sleep 5

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl create serviceaccount mega-app
  kubectl run nginx \
		--image=nginx \
		--annotations="vault.hashicorp.com/agent-inject=true" \
		--annotations="vault.hashicorp.com/role=cross-namespace-demo" \
        --annotations="vault.hashicorp.com/auth-path=us-west-org/auth/kubernetes" \
		--annotations="vault.hashicorp.com/agent-inject-secret-marketing=us-east-org/kv-marketing/campaign" \
        --annotations="vault.hashicorp.com/agent-inject-default-template=json" \
		--overrides='{ "apiVersion": "v1", "spec": { "serviceAccountName": "mega-app" } }'
	kubectl wait --for=condition=Ready --timeout=5m pod nginx

    local secret_output=$(kubectl exec nginx -c nginx -- cat /vault/secrets/marketing)
    [ "$(jq -r '.data.start_date' <<< ${secret_output})" == "March 1, 2023" ]
    [ "$(jq -r '.data.end_date' <<< ${secret_output})" == "March 31, 2023" ]
    [ "$(jq -r '.data.prise' <<< ${secret_output})" == "Certification voucher" ]
    [ "$(jq -r '.data.quantity' <<< ${secret_output})" == "100" ]
}
