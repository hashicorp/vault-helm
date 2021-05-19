#!/usr/bin/env bats

load _helpers

@test "injector: testing leader elector" {
  cd `chart_dir`
  
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  helm install "$(name_prefix)" \
    --set="injector.replicas=3" .
  kubectl wait --for condition=Ready pod -l app.kubernetes.io/name=vault-agent-injector --timeout=5m

  pods=($(kubectl get pods -l app.kubernetes.io/name=vault-agent-injector -o json | jq -r '.items[] | .metadata.name'))
  [ "${#pods[@]}" == 3 ]

  leader="$(echo "$(kubectl exec ${pods[0]} -c sidecar-injector -- wget --quiet --output-document - localhost:4040)" | jq -r .name)"
  # Check the leader name is valid - i.e. one of the 3 pods
  [[ " ${pods[@]} " =~ " ${leader} " ]]

  # Check every pod agrees on who the leader is
  for pod in "${pods[@]}"
  do
    pod_leader="$(echo "$(kubectl exec $pod -c sidecar-injector -- wget --quiet --output-document - localhost:4040)" | jq -r .name)"
    [ "${pod_leader}" == "${leader}" ]
  done
}

setup() {
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm delete vault
      kubectl delete --all pvc
      kubectl delete namespace acceptance
  fi
}