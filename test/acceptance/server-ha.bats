#!/usr/bin/env bats

load _helpers

@test "server-ha: default, comes up sealed, 1 replica" {
  helm_install_ha
  wait_for_running $(name_prefix)-ha-server-0

  # Verify installed, sealed, and 1 replica
  local sealed_status=$(kubectl exec "$(name_prefix)-ha-server-0" -- vault status -format=json | 
    jq .sealed )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-ha-server-0" -- vault status -format=json | 
    jq .initialized)
  [ "${init_status}" == "false" ]
}

# setup a consul env
setup() {
  set +e
  #if [[ "$BATS_TEST_NUMBER" -eq 1]]; then
  #  ...
  #fi
  helm install https://github.com/hashicorp/consul-helm/archive/v0.3.0.tar.gz \
    --name consul \
    --set 'ui.enabled=false' \

  wait_for_running_consul 
}

#cleanup
teardown() {
  #if [[ "${#BATS_TEST_NAMES[@]}" -eq "$BATS_TEST_NUMBER" ]]; then
  #  
  #fi
  helm delete --purge vault 
  helm delete --purge consul
  kubectl delete --all pvc 
}
