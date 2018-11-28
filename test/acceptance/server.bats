#!/usr/bin/env bats

load _helpers

@test "server: default, comes up sealed" {
  helm_install
  wait_for_running $(name_prefix)-server-0

  # Verify there are three servers
  local sealed_status=$(kubectl exec "$(name_prefix)-server-0" -- vault status -format=json | 
    jq .sealed )
  [ "${sealed_status}" == "true" ]

  local init_status=$(kubectl exec "$(name_prefix)-server-0" -- vault status -format=json | 
    jq .initialized)
  [ "${init_status}" == "false" ]
}

# Clean up
teardown() {
  echo "helm/pvc teardown"
  helm_delete
}
