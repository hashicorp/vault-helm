#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

OUTPUT=/tmp/output.txt

vault operator init -n 1 -t 1 >> ${OUTPUT?}

unseal=$(cat ${OUTPUT?} | grep "Unseal Key 1:" | sed -e "s/Unseal Key 1: //g")
root=$(cat ${OUTPUT?} | grep "Initial Root Token:" | sed -e "s/Initial Root Token: //g")

vault operator unseal ${unseal?}

vault login -no-print ${root?}

vault write sys/config/group-policy-application \
   group_policy_application_mode="any"

# Create new namespaces - they are peer
vault namespace create us-west-org
vault namespace create us-east-org

#--------------------------
# us-west-org namespace
#--------------------------
VAULT_NAMESPACE=us-west-org vault auth enable kubernetes
VAULT_NAMESPACE=us-west-org vault write auth/kubernetes/config kubernetes_host=https://kubernetes.default:443
VAULT_NAMESPACE=us-west-org vault write auth/kubernetes/role/cross-namespace-demo bound_service_account_names="mega-app" bound_service_account_namespaces="acceptance" alias_name_source="serviceaccount_name"

# Create an entity
VAULT_NAMESPACE=us-west-org vault auth list | grep -E '^kubernetes' | awk '{print $3}' > /tmp/accessor.txt
VAULT_NAMESPACE=us-west-org vault write identity/entity name="entity-for-mega-app" | grep -E '^id' | awk '{print $2}' > /tmp/entity_id.txt
VAULT_NAMESPACE=us-west-org vault write identity/entity-alias name="acceptance/mega-app" canonical_id="$(cat /tmp/entity_id.txt)" mount_accessor="$(cat /tmp/accessor.txt)"

#--------------------------
# us-east-org namespace
#--------------------------
VAULT_NAMESPACE=us-east-org vault secrets enable -path="kv-marketing" kv-v2
VAULT_NAMESPACE=us-east-org vault kv put kv-marketing/campaign start_date="March 1, 2023" end_date="March 31, 2023" prise="Certification voucher" quantity="100"

# Create a policy to allow read access to kv-marketing
VAULT_NAMESPACE=us-east-org vault policy write marketing-read-only -<<EOF
path "kv-marketing/data/campaign" {
   capabilities = ["read"]
}
EOF

# Create a group
VAULT_NAMESPACE=us-east-org vault write -format=json identity/group name="campaign-admin" policies="marketing-read-only" member_entity_ids="$(cat /tmp/entity_id.txt)"
