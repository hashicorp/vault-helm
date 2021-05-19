# chart_dir returns the directory for the chart
chart_dir() {
    echo ${BATS_TEST_DIRNAME}/../..
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
  local check=$(cat $VERIFY_OUTPUT | jq -r ".results[] | select(.check==\"${var}\").outcome")
  [ "$check" = "PASS" ]
}
