#!/usr/bin/env bats

load _helpers

@test "helm/test: running helm test" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  helm install "$(name_prefix)" .
  wait_for_running $(name_prefix)-0

  helm test "$(name_prefix)"
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm delete vault
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
  fi
}
