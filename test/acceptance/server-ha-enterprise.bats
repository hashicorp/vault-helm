#!/usr/bin/env bats

load _helpers

@test "server/ha: testing enterprise deployment: performance replica" {
  cd `chart_dir`

  helm install --name="$(name_prefix)" \
    --set='global.image=hashicorp/vault-enterprise:1.2.3_ent' \
    --set='server.ha.enabled=true' \
    -f $(chart_dir)/test/acceptance/values-primary.yaml .
  wait_for_running $(name_prefix)-0

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Vault Init
  local init=$(kubectl exec -ti "$(name_prefix)-0" -- vault operator init -format=json -n 1 -t 1)

  local token_primary=$(echo ${init?} | jq -r '.unseal_keys_b64[0]')
  [ "${token_primary}" != "" ]

  local root_primary=$(echo ${init?} | jq -r '.root_token')
  [ "${root_primary}" != "" ]

  echo ${token_primary} > /tmp/keys
  echo ${root_primary} >> /tmp/keys

  # Vault Unseal
  local pods=($(kubectl get pods --selector="app.kubernetes.io/instance=$(name_prefix)" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token_primary}
  done

  wait_for_ready "$(name_prefix)-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec -ti $(name_prefix)-0 -- vault login ${root_primary}
  kubectl exec -ti $(name_prefix)-0 -- vault write -f sys/replication/performance/primary/enable -primary_cluster_addr=https://$(name_prefix):8201

  local secondary=$(kubectl exec -ti "$(name_prefix)-0" -- vault write sys/replication/performance/primary/secondary-token id=secondary -format=json)
  [ "${secondary}" != "" ]

  local secondary_token=$(echo ${secondary} | jq -r '.wrap_info.token')
  [ "${secondary_token}" != "" ]
  echo ${secondary_token} > /tmp/sec-token

  ##### Setup secondary cluster

  helm install --name="$(name_prefix)-replica" \
    --set='global.image=hashicorp/vault-enterprise:1.2.3_ent' \
    --set='server.ha.enabled=true' \
    -f $(chart_dir)/test/acceptance/values-replica.yaml .

  wait_for_running $(name_prefix)-replica-0

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-replica-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-replica-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Vault Init
  local init=$(kubectl exec -ti "$(name_prefix)-replica-0" -- vault operator init -format=json -n 1 -t 1)

  local token_secondary=$(echo ${init?} | jq -r '.unseal_keys_b64[0]')
  [ "${token_secondary}" != "" ]

  local root_secondary=$(echo ${init?} | jq -r '.root_token')
  [ "${root_secondary}" != "" ]

  echo ${token_secondary} > /tmp/keys-replica
  echo ${root_secondary} >> /tmp/keys-replica

  # Vault Unseal
  local pods=($(kubectl get pods --selector="app.kubernetes.io/instance=$(name_prefix)-replica" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token_secondary}
  done

  wait_for_ready "$(name_prefix)-replica-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-replica-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-replica-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec -ti "$(name_prefix)-replica-0" -- vault login ${root_secondary}
  kubectl exec -ti "$(name_prefix)-replica-0" -- vault write sys/replication/performance/secondary/enable token=${secondary_token}

  sleep 10

  local pods=($(kubectl get pods --selector="app.kubernetes.io/instance=$(name_prefix)-replica" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token_primary}
  done
}

# setup a consul env
setup() {
  helm install https://github.com/hashicorp/consul-helm/archive/v0.8.1.tar.gz \
    --name consul \
    --set 'ui.enabled=false' \

  wait_for_running_consul
}

#cleanup
teardown() {
  echo ""
}
