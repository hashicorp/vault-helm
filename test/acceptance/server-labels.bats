#!/usr/bin/env bats

load _helpers

# These tests cover what the unit tests structurally cannot: that the API
# server accepts the rendered labels, and that adding them to an existing
# release does not touch an immutable field.

@test "server/labels: global.extraLabels are applied to live objects" {
  cd `chart_dir`
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" -f ./test/acceptance/server-test/labels-overrides.yaml . ${SET_CHART_VALUES}
  check_vault_versions "$(name_prefix)"
  wait_for_running $(name_prefix)-0

  # The chart-wide labels reach every kind of object, not just workloads.
  for kind in statefulset service serviceaccount; do
    local team=$(kubectl get $kind "$(name_prefix)" --output json |
      jq -r '.metadata.labels.team')
    [ "${team}" == "platform" ]
  done

  # Including objects that are not named after the release.
  local configMapTeam=$(kubectl get configmap "$(name_prefix)-config" --output json |
    jq -r '.metadata.labels.team')
  [ "${configMapTeam}" == "platform" ]

  # Numeric-looking values must survive as strings.
  local cost=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.metadata.labels.cost')
  [ "${cost}" == "1234" ]

  # The templated-string form is rendered against the release.
  local release=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.metadata.labels["release-name"]')
  [ "${release}" == "$(name_prefix)" ]

  # Labels reach the pods themselves, not only the workload metadata.
  local podTeam=$(kubectl get pod "$(name_prefix)-0" --output json |
    jq -r '.metadata.labels.team')
  [ "${podTeam}" == "platform" ]

  # Per-resource extraLabels win over the global value, with no duplicate key.
  local injectorTeam=$(kubectl get deployment "$(name_prefix)-agent-injector" --output json |
    jq -r '.metadata.labels.team')
  [ "${injectorTeam}" == "injector-team" ]

  local owner=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.metadata.labels.owner')
  [ "${owner}" == "sre" ]

  # app.kubernetes.io/version tracks each component's own image.
  local serverVersion=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.metadata.labels["app.kubernetes.io/version"]')
  [ "${serverVersion}" == "$(helm get values "$(name_prefix)" --all | yq -r '.server.image.tag')" ]

  local injectorVersion=$(kubectl get deployment "$(name_prefix)-agent-injector" --output json |
    jq -r '.metadata.labels["app.kubernetes.io/version"]')
  [ "${injectorVersion}" == "$(helm get values "$(name_prefix)" --all | yq -r '.injector.image.tag')" ]

  # Selectors must not have picked up any of the custom labels.
  local selectorTeam=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.selector.matchLabels.team // "absent"')
  [ "${selectorTeam}" == "absent" ]
}

@test "server/labels: adding labels to an existing release does not break upgrade" {
  cd `chart_dir`
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  # The injector is disabled here. Its MutatingWebhookConfiguration has an
  # empty caBundle in the chart that vault-k8s fills in at runtime, so any
  # helm upgrade conflicts with that field's owner. That is unrelated to
  # labels, and this test is about the server's immutable fields.
  local noInjector="--set injector.enabled=false"

  # Install without any custom labels first.
  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${noInjector} ${SET_CHART_VALUES}
  wait_for_running $(name_prefix)-0

  # Record the immutable fields before the upgrade.
  local selectorBefore=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -Sc '.spec.selector')
  local claimsBefore=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -Sc '.spec.volumeClaimTemplates')

  # Adding chart-wide labels to a live release must succeed. This is the case
  # that broke in the past, when the chart version label was part of the
  # selector.
  helm upgrade "$(name_prefix)" -f ./test/acceptance/server-test/labels-overrides.yaml . ${noInjector} ${SET_CHART_VALUES}
  wait_for_running $(name_prefix)-0

  local team=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.metadata.labels.team')
  [ "${team}" == "platform" ]

  # The immutable fields must be byte-identical afterwards.
  local selectorAfter=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -Sc '.spec.selector')
  [ "${selectorBefore}" == "${selectorAfter}" ]

  local claimsAfter=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -Sc '.spec.volumeClaimTemplates')
  [ "${claimsBefore}" == "${claimsAfter}" ]

  # Changing a label value on a live release must also succeed. global.extraLabels
  # is a YAML string here, so the whole value is replaced rather than one key.
  helm upgrade "$(name_prefix)" -f ./test/acceptance/server-test/labels-overrides.yaml . \
    --set 'global.extraLabels=team: platform-two' ${noInjector} ${SET_CHART_VALUES}
  wait_for_running $(name_prefix)-0

  local updated=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.metadata.labels.team')
  [ "${updated}" == "platform-two" ]

  # The immutable fields must still be untouched after a label change.
  local selectorFinal=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -Sc '.spec.selector')
  [ "${selectorBefore}" == "${selectorFinal}" ]
}

@test "server/labels: changing global.extraLabels rolls the pods" {
  cd `chart_dir`
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  # The server defaults to OnDelete, which leaves existing pods alone when the
  # pod template changes. RollingUpdate is set here so the rollout is
  # observable, which is what the injector and CSI provider do by default.
  local opts="--set injector.enabled=false --set server.updateStrategyType=RollingUpdate"

  eval "${PRE_CHART_CMDS}"
  helm install "$(name_prefix)" . ${opts} --set 'global.extraLabels=team: platform' ${SET_CHART_VALUES}
  wait_for_running $(name_prefix)-0

  local uidBefore=$(kubectl get pod "$(name_prefix)-0" --output json | jq -r '.metadata.uid')

  helm upgrade "$(name_prefix)" . ${opts} --set 'global.extraLabels=team: platform-two' ${SET_CHART_VALUES}

  # Wait for the pod to come back with the new label.
  for i in $(seq 60); do
    local current=$(kubectl get pod "$(name_prefix)-0" --output json 2>/dev/null | jq -r '.metadata.labels.team // "none"')
    [ "${current}" == "platform-two" ] && break
    sleep 2
  done
  wait_for_running $(name_prefix)-0

  local uidAfter=$(kubectl get pod "$(name_prefix)-0" --output json | jq -r '.metadata.uid')
  local teamAfter=$(kubectl get pod "$(name_prefix)-0" --output json | jq -r '.metadata.labels.team')

  [ "${teamAfter}" == "platform-two" ]
  # A new UID means the pod was recreated rather than patched in place.
  [ "${uidBefore}" != "${uidAfter}" ]
}

@test "server/labels: a chart-managed label is rejected before anything is applied" {
  cd `chart_dir`
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  eval "${PRE_CHART_CMDS}"
  run helm install "$(name_prefix)" . \
      --set 'global.extraLabels=component: hacked' ${SET_CHART_VALUES}

  [ "$status" -ne 0 ]
  [[ "$output" =~ "is managed by the chart and cannot be overridden" ]]

  # Nothing may have been created, and the release must not exist.
  [ "$(kubectl get statefulset "$(name_prefix)" --ignore-not-found --output name)" == "" ]
  [ "$(helm list --short --filter "^$(name_prefix)$")" == "" ]
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm delete $(name_prefix)
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
      kubectl config unset contexts."$(kubectl config current-context)".namespace
  fi
}
