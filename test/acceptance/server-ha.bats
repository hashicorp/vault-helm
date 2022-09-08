#!/usr/bin/env bats

load _helpers

@test "server/ha: testing deployment" {
  cd `chart_dir`

  helm install "$(name_prefix)" \
    --set='server.ha.enabled=true' .
  wait_for_running $(name_prefix)-0

  # Sealed, not initialized
  wait_for_sealed_vault $(name_prefix)-0

  local init_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "false" ]

  # Replicas
  local replicas=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.replicas')
  [ "${replicas}" == "3" ]

  # Volume Mounts
  local volumeCount=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.spec.containers[0].volumeMounts | length')
  [ "${volumeCount}" == "2" ]

  # Volumes
  local volumeCount=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.spec.volumes | length')
  [ "${volumeCount}" == "2" ]

  local volume=$(kubectl get statefulset "$(name_prefix)" --output json |
    jq -r '.spec.template.spec.volumes[0].configMap.name')
  [ "${volume}" == "$(name_prefix)-config" ]

  # Service
  local service=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.clusterIP')
  [ "${service}" != "None" ]

  local service=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.type')
  [ "${service}" == "ClusterIP" ]

  local ports=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.ports | length')
  [ "${ports}" == "2" ]

  local ports=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.ports[0].port')
  [ "${ports}" == "8200" ]

  local ports=$(kubectl get service "$(name_prefix)" --output json |
    jq -r '.spec.ports[1].port')
  [ "${ports}" == "8201" ]

  # Vault Init
  local token=$(kubectl exec -ti "$(name_prefix)-0" -- \
    vault operator init -format=json -n 1 -t 1 | \
    jq -r '.unseal_keys_b64[0]')
  [ "${token}" != "" ]

  # Vault Unseal
  local pods=($(kubectl get pods --selector='app.kubernetes.io/name=vault' -o json | jq -r '.items[].metadata.name'))
  for pod in "${pods[@]}"
  do
      kubectl exec -ti ${pod} -- vault operator unseal ${token}
  done

  wait_for_ready "$(name_prefix)-0"

  # Sealed, not initialized
  local sealed_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.sealed' )
  [ "${sealed_status}" == "false" ]

  local init_status=$(kubectl exec "$(name_prefix)-0" -- vault status -format=json |
    jq -r '.initialized')
  [ "${init_status}" == "true" ]
}

# setup a consul env
setup() {
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance
  kubectl config set-context --current --namespace=acceptance

  helm repo add hashicorp https://helm.releases.hashicorp.com
  helm repo update

  CONSUL_HELM_VERSION=v0.48.0

  K8S_MAJOR=$(kubectl version --output=json | jq -r .serverVersion.major)
  K8S_MINOR=$(kubectl version --output=json | jq -r .serverVersion.minor)
  if [ \( $K8S_MAJOR -eq 1 \) -a \( $K8S_MINOR -le 20 \) ]; then
    CONSUL_HELM_VERSION=v0.32.1
  fi
  helm install consul hashicorp/consul \
    --version $CONSUL_HELM_VERSION \
    --set 'ui.enabled=false'

  wait_for_running_consul
}

#cleanup
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      # If the test failed, print some debug output
      if [[ "$BATS_ERROR_STATUS" -ne 0 ]]; then
          kubectl logs -l app=consul
          kubectl logs -l app.kubernetes.io/name=vault
      fi
      helm delete vault
      helm delete consul
      kubectl delete --all pvc
      kubectl delete namespace acceptance --ignore-not-found=true
  fi
}
