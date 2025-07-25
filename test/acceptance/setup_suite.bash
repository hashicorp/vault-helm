#!/usr/bin/env bats

setup_suite() {
    local INJECTOR_AGENT_VERSION SERVER_VAULT_VERSION CSI_AGENT_VERSION CHART_VALUES
    if [ -z ${VAULT_VERSION+x} ]; then
        # If VAULT_VERSION is not set, use the defaults from values.yaml
        INJECTOR_AGENT_VERSION=$(yq -r '.injector.agentImage.tag' values.yaml)
        SERVER_VAULT_VERSION=$(yq -r '.server.image.tag' values.yaml)
        CSI_AGENT_VERSION=$(yq -r '.csi.image.tag' values.yaml)
    else
        INJECTOR_AGENT_VERSION=${VAULT_VERSION}
        SERVER_VAULT_VERSION=${VAULT_VERSION}
        CSI_AGENT_VERSION=${VAULT_VERSION}
    fi

    local VAULT_REPOSITORY
    VAULT_REPOSITORY=${VAULT_REPOSITORY:-hashicorp/vault}

    PRE_CHART_CMDS=""
    if [ -n "${ENT_TESTS}" ]; then
        SERVER_VAULT_VERSION="${SERVER_VAULT_VERSION}-ent"
        INJECTOR_AGENT_VERSION="${INJECTOR_AGENT_VERSION}-ent"
        CSI_AGENT_VERSION="${CSI_AGENT_VERSION}-ent"
        VAULT_REPOSITORY="hashicorp/vault-enterprise"
        VAULT_LICENSE_CI=${VAULT_LICENSE_CI:?"VAULT_LICENSE_CI must be set"}
        CHART_VALUES+=(--set server.enterpriseLicense.secretName=vault-license)
        PRE_CHART_CMDS+="kubectl create secret generic vault-license --from-literal=license=${VAULT_LICENSE_CI?}"
    fi

    CHART_VALUES+=(--set injector.agentImage.tag="${INJECTOR_AGENT_VERSION}")
    CHART_VALUES+=(--set injector.agentImage.repository="${VAULT_REPOSITORY}")
    CHART_VALUES+=(--set server.image.tag="${SERVER_VAULT_VERSION}")
    CHART_VALUES+=(--set server.image.repository="${VAULT_REPOSITORY}")
    CHART_VALUES+=(--set csi.agent.image.tag="${CSI_AGENT_VERSION}")
    CHART_VALUES+=(--set csi.agent.image.repository="${VAULT_REPOSITORY}")

    echo "Using chart values: ${CHART_VALUES[*]}" >&3
    SET_CHART_VALUES=${CHART_VALUES[*]}
    export SET_CHART_VALUES PRE_CHART_CMDS
}
