#!/usr/bin/env bats

load _helpers

@test "server: default, comes up healthy" {
  helm_install
  wait_for_ready $(name_prefix)-server-0

  # Verify there are three servers
  local server_count=$(kubectl exec "$(name_prefix)-server-0" consul members |
      grep server |
      wc -l)
  [ "${server_count}" -eq "3" ]

  # Clean up
  helm_delete
}
