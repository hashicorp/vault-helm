#!/usr/bin/env bats

load _helpers

@test "server/telemetry: prometheusOperator" {
  cd `chart_dir`
  helm --namespace acceptance uninstall $(name_prefix) || :
  helm --namespace acceptance uninstall prometheus || :
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  # Install prometheus-operator and friends.
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  helm upgrade --install \
    --wait \
    --version 58.3.1 \
    prometheus prometheus-community/kube-prometheus-stack

  # Install Vault with telemetry config now that the prometheus CRDs are applied.
  helm upgrade --install \
    --wait \
    --values ./test/acceptance/server-test/vault-server.yaml \
    --values ./test/acceptance/server-test/vault-telemetry.yaml \
    "$(name_prefix)" .

  wait_for_ready "$(name_prefix)-0"

  echo 'path "sys/metrics" {capabilities = ["read"]}' | kubectl exec -i "$(name_prefix)-0" -- vault policy write metrics -

  # Store Vault's dev TLS CA and a token in a secret for prometheus to use.
  kubectl create secret generic vault-metrics-client \
    --from-literal="ca.crt=$(kubectl exec "$(name_prefix)-0" -- cat /var/run/tls/vault-ca.pem)" \
    --from-literal="token=$(kubectl exec "$(name_prefix)-0" -- vault token create -policy=metrics -field=token)"

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
