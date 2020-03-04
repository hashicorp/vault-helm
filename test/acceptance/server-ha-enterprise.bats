#!/usr/bin/env bats

load _helpers

@test "server/ha enterprise: testing enterprise deployment: performance replica" {
  cd `chart_dir`

  helm install --name="$(name_prefix)-us-east" \
    --set='global.image=hashicorp/vault-enterprise:1.2.3_ent' \
    --set='server.ha.enabled=true' \
    -f $(chart_dir)/test/acceptance/values-us-east.yaml .

  # Breathing room
  sleep 5
  wait_for_not_ready "$(name_prefix)-us-east-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-us-east-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-us-east-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Vault Init
  local init=$(kubectl exec -ti "$(name_prefix)-us-east-0" -- vault operator init -format=json -n 1 -t 1)

  local token_primary=$(echo ${init?} | jq -r '.unseal_keys_b64[0]')
  [ "${token_primary}" != "" ]

  local root_primary=$(echo ${init?} | jq -r '.root_token')
  [ "${root_primary}" != "" ]

  # Vault Unseal
  local pods=($(kubectl get pods --selector="app.kubernetes.io/instance=$(name_prefix)-us-east" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token_primary}
  done

  wait_for_ready "$(name_prefix)-us-east-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-us-east-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-us-east-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec -ti $(name_prefix)-us-east-0 -- vault login ${root_primary}
  kubectl exec -ti $(name_prefix)-us-east-0 -- vault write -f sys/replication/performance/primary/enable -primary_cluster_addr=https://$(name_prefix):8201

  local secondary=$(kubectl exec -ti "$(name_prefix)-us-east-0" -- vault write sys/replication/performance/primary/secondary-token id=secondary -format=json)
  [ "${secondary}" != "" ]

  local secondary_token=$(echo ${secondary} | jq -r '.wrap_info.token')
  [ "${secondary_token}" != "" ]
  echo ${secondary_token} > /tmp/sec-token

  ##### Setup secondary cluster

  helm install --name="$(name_prefix)-us-west" \
    --set='global.image=hashicorp/vault-enterprise:1.2.3_ent' \
    --set='server.ha.enabled=true' \
    -f $(chart_dir)/test/acceptance/values-us-west.yaml .

  # Breathing room
  sleep 5
  wait_for_not_ready "$(name_prefix)-us-west-0"
  
  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-us-west-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-us-west-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Vault Init
  local init=$(kubectl exec -ti "$(name_prefix)-us-west-0" -- vault operator init -format=json -n 1 -t 1)

  local token_secondary=$(echo ${init?} | jq -r '.unseal_keys_b64[0]')
  [ "${token_secondary}" != "" ]

  local root_secondary=$(echo ${init?} | jq -r '.root_token')
  [ "${root_secondary}" != "" ]

  # Vault Unseal
  local pods=($(kubectl get pods --selector="app.kubernetes.io/instance=$(name_prefix)-us-west" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token_secondary}
  done

  wait_for_ready "$(name_prefix)-us-west-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-us-west-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-us-west-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec -ti "$(name_prefix)-us-west-0" -- vault login ${root_secondary}
  kubectl exec -ti "$(name_prefix)-us-west-0" -- vault write sys/replication/performance/secondary/enable token=${secondary_token}

  local pods=($(kubectl get pods --selector="app.kubernetes.io/instance=$(name_prefix)-us-west" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      if [[ ${pod?} != "$(name_prefix)-us-west-0" ]]
      then
          wait_for_not_ready "${pod?}"
          kubectl exec -ti ${pod} -- vault operator unseal ${token_primary}
      fi
  done

  local pods=($(kubectl get pods --selector="app=consul" -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      wait_for_ready "${pod?}"
  done  
}

# setup a consul env
setup() {

  helm install consul https://github.com/hashicorp/consul-helm/archive/v0.8.1.tar.gz \
    --set 'ui.enabled=false' \
    --set server.affinity=null \
    --wait
}

#cleanup
teardown() {
  helm delete --purge consul
  helm delete --purge vault-us-east
  helm delete --purge vault-us-west
  kubectl delete pvc --all
}
