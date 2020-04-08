#!/bin/bash
set +x
while ! nslookup vault </dev/null || ! nc -w1 vault 8200 </dev/null; do
    echo "Waiting for Vault to Come up!"
    sleep 0.1
done
sleep 10

echo "Vault Up, Will be initlising the it"

export VAULT_ADDR=http://$VAULT_SERVICE_HOST:$VAULT_SERVICE_PORT_HTTP
echo "vault address is: $VAULT_ADDR"

echo "Initialising the vault"
vault operator init -n 1 -t 1 > /tmp/stdout
cat /tmp/stdout | head -n 1 | awk '{print $4}' > /tmp/key
cat /tmp/stdout | grep -i "Root" |awk '{print $4}' > /tmp/token
export KEY=$(cat /tmp/key)
export VAULT_TOKEN=$(cat /tmp/token)

echo "vault key is : $KEY"
echo "vault token is : $VAULT_TOKEN"

echo "Unsealing the vault"
vault operator unseal $KEY
vault status

if [ "{{.Values.initvault.ldapauth.enabled}}" == "true" ]; then
    echo "Enabling the LDAP auth"
    export ldap_url="{{.Values.initvault.ldapauth.ldap_url}}"
    export userattr="{{.Values.initvault.ldapauth.userattr}}"
    export userdn="{{.Values.initvault.ldapauth.userdn}}"
    export groupdn="{{.Values.initvault.ldapauth.groupdn}}"
    export upndomain="{{.Values.initvault.ldapauth.upndomain}}"
    vault auth enable ldap
    vault login $VAULT_TOKEN
    vault write auth/ldap/config \
        url="${ldap_url}" \
        userattr="${userattr}" \
        userdn="${userdn}" \
        groupdn="${groupdn}" \
        upndomain="${upndomain}" \
        insecure_tls=true starttls=true \
        tls_min_version=tls10
fi