#!/usr/bin/env bats

load _helpers

@test "injector: testing leader elector" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  helm install "$(name_prefix)" \
    --wait \
    --timeout=5m \
    --set="injector.replicas=3" .
  kubectl wait --for condition=Ready pod -l app.kubernetes.io/name=vault-agent-injector --timeout=5m

  pods=($(kubectl get pods -l app.kubernetes.io/name=vault-agent-injector -o json | jq -r '.items[] | .metadata.name'))
  [ "${#pods[@]}" == 3 ]

  leader=''
  tries=0
  until [ $tries -ge 60 ]
  do
    owner=$(kubectl get configmaps vault-k8s-leader -o json | jq -r .metadata.ownerReferences\[0\].name)
    leader=$(kubectl get pods $owner -o json | jq -r .metadata.name)
    [ -n "${leader}" ] && [ "${leader}" != "null" ] && break
    ((++tries))
    sleep .5
  done

  # Check the leader name is valid - i.e. one of the 3 pods
  [[ " ${pods[@]} " =~ " ${leader} " ]]

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