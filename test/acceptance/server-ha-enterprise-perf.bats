#!/usr/bin/env bats

load _helpers

@test "server/ha-enterprise-raft: testing performance replica deployment" {
  cd `chart_dir`

  helm install "$(name_prefix)-east" \
    --set='injector.enabled=false' \
    --set='server.image.repository=hashicorp/vault-enterprise' \
    --set='server.image.tag=1.4.0_ent' \
    --set='server.ha.enabled=true' \
    --set='server.ha.raft.enabled=true' .
  wait_for_running "$(name_prefix)-east-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-east-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-east-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Vault Init
  local init=$(kubectl exec -ti "$(name_prefix)-east-0" -- \
    vault operator init -format=json -n 1 -t 1)

  local primary_token=$(echo ${init} | jq -r '.unseal_keys_b64[0]')
  [ "${primary_token}" != "" ]
  
  local primary_root=$(echo ${init} | jq -r '.root_token')
  [ "${primary_root}" != "" ]

  kubectl exec -ti "$(name_prefix)-east-0" -- vault operator unseal ${primary_token}
  wait_for_ready "$(name_prefix)-east-0"

  sleep 10

  # Vault Unseal
  local pods=($(kubectl get pods --selector='app.kubernetes.io/name=vault' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      if [[ ${pod?} != "$(name_prefix)-east-0" ]]
      then
          kubectl exec -ti ${pod} -- vault operator raft join http://$(name_prefix)-east-0.$(name_prefix)-east-internal:8200
          kubectl exec -ti ${pod} -- vault operator unseal ${primary_token}
          wait_for_ready "${pod}"
      fi
  done

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-east-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-east-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec "$(name_prefix)-east-0" -- vault login ${primary_root}

  local raft_status=$(kubectl exec "$(name_prefix)-east-0" -- vault operator raft list-peers -format=json | 
    jq -r '.data.config.servers | length')
  [ "${raft_status}" == "3" ]

  kubectl exec -ti $(name_prefix)-east-0 -- vault write -f sys/replication/performance/primary/enable primary_cluster_addr=https://$(name_prefix)-east-active:8201

  local secondary=$(kubectl exec -ti "$(name_prefix)-east-0" -- vault write sys/replication/performance/primary/secondary-token id=secondary -format=json)
  [ "${secondary}" != "" ]

  local secondary_replica_token=$(echo ${secondary} | jq -r '.wrap_info.token')
  [ "${secondary_replica_token}" != "" ]

  # Install vault-west
  helm install "$(name_prefix)-west" \
    --set='injector.enabled=false' \
    --set='server.image.repository=hashicorp/vault-enterprise' \
    --set='server.image.tag=1.4.0_ent' \
    --set='server.ha.enabled=true' \
    --set='server.ha.raft.enabled=true' .
  wait_for_running "$(name_prefix)-west-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-west-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-west-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Vault Init
  local init=$(kubectl exec -ti "$(name_prefix)-west-0" -- \
    vault operator init -format=json -n 1 -t 1)

  local secondary_token=$(echo ${init} | jq -r '.unseal_keys_b64[0]')
  [ "${secondary_token}" != "" ]

  local secondary_root=$(echo ${init} | jq -r '.root_token')
  [ "${secondary_root}" != "" ]

  kubectl exec -ti "$(name_prefix)-west-0" -- vault operator unseal ${secondary_token}
  wait_for_ready "$(name_prefix)-west-0"

  sleep 10

  # Vault Unseal
  local pods=($(kubectl get pods --selector='app.kubernetes.io/instance=vault-west' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      if [[ ${pod?} != "$(name_prefix)-west-0" ]]
      then
          kubectl exec -ti ${pod} -- vault operator raft join http://$(name_prefix)-west-0.$(name_prefix)-west-internal:8200
          kubectl exec -ti ${pod} -- vault operator unseal ${secondary_token}
          wait_for_ready "${pod}"
      fi
  done

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-west-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-west-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]

  kubectl exec "$(name_prefix)-west-0" -- vault login ${secondary_root}

  local raft_status=$(kubectl exec "$(name_prefix)-west-0" -- vault operator raft list-peers -format=json |
    jq -r '.data.config.servers | length')
  [ "${raft_status}" == "3" ]

  kubectl exec -ti "$(name_prefix)-west-0" -- vault write sys/replication/performance/secondary/enable token=${secondary_replica_token}

  sleep 10

  local pods=($(kubectl get pods --selector='app.kubernetes.io/instance=vault-west' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      if [[ ${pod?} != "$(name_prefix)-west-0" ]]
      then
          kubectl exec -ti ${pod} -- vault operator unseal ${primary_token}
          wait_for_ready "${pod}"
      fi
  done
}

setup() {
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance
}

#cleanup
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      helm delete vault-east
      helm delete vault-west
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
  fi
}
