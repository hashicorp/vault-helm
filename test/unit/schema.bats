#!/usr/bin/env bats

load _helpers

# These tests are just to verify there is a schema file used in the chart. Since
# .enabled is defined as a boolean type for each of the top-level blocks in the
# schema, setting it as a string fails 'helm template'.
@test "schema: csi enabled datatype" {
  cd `chart_dir`
  run helm template . --set csi.enabled="123"
  [ "$status" -eq 1 ]
  [ "${lines[2]}" = "- csi.enabled: Invalid type. Expected: [boolean,string], given: integer" ]

  run helm template . --set csi.enabled=true
  [ "$status" -eq 0 ]
}

@test "schema: injector enabled datatype" {
  cd `chart_dir`
  run helm template . --set injector.enabled="123"
  [ "$status" -eq 1 ]
  [ "${lines[2]}" = "- injector.enabled: Invalid type. Expected: [boolean,string], given: integer" ]

  run helm template . --set injector.enabled=true
  [ "$status" -eq 0 ]
}

@test "schema: server enabled datatype" {
  cd `chart_dir`
  run helm template . --set server.enabled="123"
  [ "$status" -eq 1 ]
  [ "${lines[2]}" = "- server.enabled: Invalid type. Expected: [boolean,string], given: integer" ]

  run helm template . --set server.enabled=true
  [ "$status" -eq 0 ]
}

@test "schema: ui enabled datatype" {
  cd `chart_dir`
  run helm template . --set ui.enabled="123"
  [ "$status" -eq 1 ]
  [ "${lines[2]}" = "- ui.enabled: Invalid type. Expected: [boolean,string], given: integer" ]

  run helm template . --set ui.enabled=true
  [ "$status" -eq 0 ]
}
