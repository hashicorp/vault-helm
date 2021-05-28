# chart_dir returns the directory for the chart
chart_dir() {
    echo ${BATS_TEST_DIRNAME}/../..
}

check_image() {
  local -r container="$1"
  local -r imageRepo="$2"
  local -r imageTag="$3"

  local image=$(echo $container |
      yq -r '.image' | tee /dev/stderr)
  [ "${image}" = "${imageRepo}:${imageTag}" ]
}

check_agentImage() {
  local -r container="$1"
  local -r agentRepo="$2"
  local -r agentTag="$3"

  local agentImage=$(echo $container |
      yq -r '.env | map(select(.name=="AGENT_INJECT_VAULT_IMAGE")) | .[] .value' | tee /dev/stderr)
  [ "${agentImage}" = "${agentRepo}:${agentTag}" ]
}
