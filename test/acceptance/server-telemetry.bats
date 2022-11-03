#!/usr/bin/env bats

load _helpers

@test "server/telemetry: prometheusOperator" {
  cd `chart_dir`
  helm --namespace acceptance uninstall $(name_prefix) || :
  helm --namespace acceptance uninstall prometheus || :
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  helm install \
    --wait \
    --version 39.6.0 \
    prometheus prometheus-community/kube-prometheus-stack

  helm install \
    --wait \
    --values ./test/acceptance/server-test/telemetry.yaml \
    "$(name_prefix)" .

  wait_for_running $(name_prefix)-0

  # Sealed, not initialized
  wait_for_sealed_vault $(name_prefix)-0

  # Vault Init
  local token=$(kubectl exec -ti "$(name_prefix)-0" -- \
    vault operator init -format=json -n 1 -t 1 | \
    jq -r '.unseal_keys_b64[0]')
  [ "${token}" != "" ]

  # Vault Unseal
  local pods=($(kubectl get pods --selector='app.kubernetes.io/name=vault' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token}
  done

  wait_for_ready "$(name_prefix)-0"

  # Unsealed, initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  # unfortunately it can take up to 2 minutes for the vault prometheus job to appear
  # TODO: investigate how reduce this.
  local job_labels
  local tries=0
  until [ $tries -ge 240 ]
  do
      job_labels=$( (kubectl exec -n acceptance svc/prometheus-kube-prometheus-prometheus \
        -c prometheus \
        -- wget -q -O - http://127.0.0.1:9090/api/v1/label/job/values) | tee /dev/stderr )

      # Ensure the expected job label was picked up by Prometheus
      [ "$(echo "${job_labels}" | jq 'any(.data[]; . == "vault-internal")')" = "true" ] && break

      ((++tries))
      sleep .5
    done


  # Ensure the expected job is "up"
  local job_up=$( ( kubectl exec -n acceptance svc/prometheus-kube-prometheus-prometheus \
    -c prometheus \
    -- wget -q -O - 'http://127.0.0.1:9090/api/v1/query?query=up{job="vault-internal"}' ) | \
    tee /dev/stderr )
  [ "$(echo "${job_up}" | jq '.data.result[0].value[1]')" = \"1\" ]
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm uninstall $(name_prefix)
      helm uninstall prometheus
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
  fi
}
