#!/usr/bin/env bats

load _helpers

@test "server/annotations: testing yaml and yaml-formatted string formats" {
  cd `chart_dir`
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  helm install "$(name_prefix)" -f ./test/acceptance/server-test/annotations-overrides.yaml .
  wait_for_running $(name_prefix)-0

  # service annotations
  local awesome=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.metadata.annotations.active')
  [ "${awesome}" == "sometimes" ]

  local pickMe=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.metadata.annotations.pickMe')
  [ "${pickMe}" == "please" ]

  local environment=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.metadata.annotations.environment')
  [ "${environment}" == "production" ]

  local milk=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.metadata.annotations.milk')
  [ "${milk}" == "oat" ]

  local myName=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.metadata.annotations.myName')
  [ "${myName}" == "$(name_prefix)" ]

}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm delete $(name_prefix)
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
  fi
}
