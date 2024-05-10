# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# chart_dir returns the directory for the chart
chart_dir() {
    echo "${BATS_TEST_DIRNAME}"/../..
}

# check_result checks if the specified test passed
# results schema example:
# {
#   "check": "has-minkubeversion",
#   "type": "Mandatory",
#   "outcome": "PASS",
#   "reason": "Minimum Kubernetes version specified"
# }
check_result() {
  local -r var="$1"
  local -r check=$(jq -r ".results[] | select(.check==\"${var}\")" < "$VERIFY_OUTPUT")
  local -r outcome=$(jq -r .outcome <<< "$check")
  local -r reason=$(jq -r .reason <<< "$check")

  # print the reason if this fails
  echo "reason: ${reason}"

  [ "$outcome" = "PASS" ]
}
