#!/usr/bin/env bats

load _helpers

@test "csi: testing deployment" {
  cd `chart_dir`

  kubectl delete namespace acceptance --ignore-not-found=true
  kubectl create namespace acceptance

  # Install Secrets Store CSI driver
  # Configure it to pass in a JWT for the provider to use, and rotate secrets rapidly
  # so we can see Agent's cache working.
  CSI_DRIVER_VERSION=1.3.2
  helm install secrets-store-csi-driver secrets-store-csi-driver \
    --repo https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts \
    --version=$CSI_DRIVER_VERSION \
    --wait --timeout=5m \
    --namespace=acceptance \
    --set linux.image.pullPolicy="IfNotPresent" \
    --set tokenRequests[0].audience="vault" \
    --set enableSecretRotation=true \
    --set rotationPollInterval=5s
  # Install Vault and Vault provider
  helm install vault \
    --wait --timeout=5m \
    --namespace=acceptance \
    --set="server.dev.enabled=true" \
    --set="csi.enabled=true" \
    --set="csi.debug=true" \
    --set="csi.agent.logLevel=debug" \
    --set="injector.enabled=false" \
    .
  kubectl --namespace=acceptance wait --for=condition=Ready --timeout=5m pod -l app.kubernetes.io/name=vault
  kubectl --namespace=acceptance wait --for=condition=Ready --timeout=5m pod -l app.kubernetes.io/name=vault-csi-provider

  # Set up k8s auth and a kv secret.
  cat ./test/acceptance/csi-test/vault-policy.hcl | kubectl --namespace=acceptance exec -i vault-0 -- vault policy write kv-policy -
  kubectl --namespace=acceptance exec vault-0 -- vault auth enable kubernetes
  kubectl --namespace=acceptance exec vault-0 -- sh -c 'vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"'
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

  for i in $(seq 10); do
    sleep 2
    if [ "$(kubectl --namespace=acceptance logs --tail=-1 -l "app.kubernetes.io/name=vault-csi-provider" -c vault-agent | grep "secret renewed: path=/v1/auth/kubernetes/login")" ]; then
        echo "Agent returned a cached login response"
        return
    fi

    echo "Waiting to confirm the Agent is renewing CSI's auth token..."
  done

  # Print the logs and fail the test
  echo "Failed to find a log for the Agent renewing CSI's auth token"
  kubectl --namespace=acceptance logs --tail=-1 -l "app.kubernetes.io/name=vault-csi-provider" -c vault-agent
  kubectl --namespace=acceptance logs --tail=-1 -l "app.kubernetes.io/name=vault-csi-provider" -c vault-csi-provider
  exit 1
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
