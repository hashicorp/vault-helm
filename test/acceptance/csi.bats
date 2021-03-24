#!/usr/bin/env bats

load _helpers

@test "csi: testing deployment" {
  cd `chart_dir`
  
  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance

  # Install Secrets Store CSI driver
  helm install secrets-store-csi-driver https://github.com/kubernetes-sigs/secrets-store-csi-driver/blob/master/charts/secrets-store-csi-driver-0.0.20.tgz?raw=true \
    --wait --timeout=5m \
    --namespace=acceptance \
    --set linux.image.pullPolicy="IfNotPresent"
  # Install Vault and Vault provider
  helm install vault \
    --wait --timeout=5m \
    --namespace=acceptance \
    --set="server.dev.enabled=true" \
    --set="csi.enabled=true" \
    --set="injector.enabled=false" .
  kubectl --namespace=acceptance wait --for=condition=Ready --timeout=5m pod -l app.kubernetes.io/name=vault
  kubectl --namespace=acceptance wait --for=condition=Ready --timeout=5m pod -l app.kubernetes.io/name=vault-csi-provider

  # Set up k8s auth and a kv secret.
  cat ./test/acceptance/csi-test/vault-policy.hcl | kubectl --namespace=acceptance exec -i vault-0 -- vault policy write kv-policy -
  kubectl --namespace=acceptance exec vault-0 -- vault auth enable kubernetes
  kubectl --namespace=acceptance exec vault-0 -- sh -c 'vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    disable_iss_validation=true'
  kubectl --namespace=acceptance exec vault-0 -- vault write auth/kubernetes/role/kv-role \
    bound_service_account_names=nginx \
    bound_service_account_namespaces=acceptance \
    policies=kv-policy \
    ttl=20m
  kubectl --namespace=acceptance exec vault-0 -- vault kv put secret/kv1 bar1=hello1

  kubectl --namespace=acceptance apply -f ./test/acceptance/csi-test/vault-kv-secretproviderclass.yaml
  kubectl --namespace=acceptance apply -f ./test/acceptance/csi-test/nginx.yaml
  kubectl --namespace=acceptance wait --for=condition=Ready --timeout=5m pod nginx

  result=$(kubectl --namespace=acceptance exec nginx -- cat /mnt/secrets-store/bar)
  [[ "$result" == "hello1" ]]
}

# Clean up
teardown() {
  if [[ ${CLEANUP:-true} == "true" ]]
  then
      echo "helm/pvc teardown"
      helm --namespace=acceptance delete vault
      helm --namespace=acceptance delete secrets-store-csi-driver
      kubectl delete --all pvc
      kubectl delete namespace acceptance
  fi
}
