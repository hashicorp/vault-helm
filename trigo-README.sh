# Prerequisites:
  - Access to cluster and project 
  - Helm
  - This repo


# To install vault to a namespace run
                      
                   override from file
                      |
helm install vault . -f trigo-override.yaml
                   |              |
                /helm-vault       |
                                yaml that overrides some values.yaml entries

# For Raft (ha setup)

- connect to first pod ( oc get pods )
oc rsh vault-0

# for just one unsealing key: (otherwise change shares and threshold, threshold determines how many of the keys are required to unseal)

vault operator init -key-shares=1 -key-threshold=1
# SAVE KEY AND TOKEN! without them the vault cannot be operated or unsealed in the future
vault operator unseal

#then: 
- connect to next pod

# DO NOT INIT OR UNSEAL! first join:
vault operator raft join http://vault-0.vault-internal:8200
vault operator unseal # with the key from vault-0

- connect to next pod

vault operator raft join http://vault-0.vault-internal:8200
vault operator unseal # with the key from vault-0

# you can check your progress now with:
vault login #provide token from above

vault operator raft list-peers


# more info: https://www.vaultproject.io/docs/platform/k8s/helm/examples/ha-with-raft