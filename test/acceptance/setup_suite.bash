#!/usr/bin/env bats
# Copyright IBM Corp. 2018, 2026


setup_suite() {
    local INJECTOR_AGENT_VERSION SERVER_VAULT_VERSION CSI_AGENT_VERSION CHART_VALUES
    if [ -n "${VAULT_VERSION}" ]; then
        INJECTOR_AGENT_VERSION=${VAULT_VERSION}
        SERVER_VAULT_VERSION=${VAULT_VERSION}
        CSI_AGENT_VERSION=${VAULT_VERSION}
    else
        # If VAULT_VERSION is not set, use the defaults from values.yaml,
        # falling back to Chart.AppVersion when tag is empty (mirrors helper logic).
        local CHART_APP_VERSION
        CHART_APP_VERSION=$(yq -r '.appVersion' Chart.yaml)
        INJECTOR_AGENT_VERSION=$(yq -r '.injector.agentImage.tag' values.yaml)
        INJECTOR_AGENT_VERSION=${INJECTOR_AGENT_VERSION:-${CHART_APP_VERSION}}
        SERVER_VAULT_VERSION=$(yq -r '.server.image.tag' values.yaml)
        SERVER_VAULT_VERSION=${SERVER_VAULT_VERSION:-${CHART_APP_VERSION}}
        CSI_AGENT_VERSION=$(yq -r '.csi.agent.image.tag' values.yaml)
        CSI_AGENT_VERSION=${CSI_AGENT_VERSION:-${CHART_APP_VERSION}}
    fi

    # NOTE: declare and assign on the same line — `local VAULT_REPOSITORY`
    # followed by a separate assignment would shadow the exported value with
    # an empty local before the ${VAULT_REPOSITORY:-default} expansion runs.
    local VAULT_REPOSITORY="${VAULT_REPOSITORY:-hashicorp/vault}"

    PRE_CHART_CMDS=""
    if [ "${ENT_TESTS}" = "true" ]; then
        SERVER_VAULT_VERSION="${SERVER_VAULT_VERSION}-ent"
        INJECTOR_AGENT_VERSION="${INJECTOR_AGENT_VERSION}-ent"
        CSI_AGENT_VERSION="${CSI_AGENT_VERSION}-ent"
        VAULT_LICENSE_CI=${VAULT_LICENSE_CI:?"VAULT_LICENSE_CI must be set"}
        # Set the license secret — this is what triggers the chart helpers
        # (vault.imageRepository/Tag, vault.agentImageRepository/Tag,
        # vault.csiAgentImageRepository/Tag) to auto-select hashicorp/vault-enterprise.
        CHART_VALUES+=(--set server.enterpriseLicense.secretName=vault-license)
        PRE_CHART_CMDS+="kubectl create secret generic vault-license --from-literal=license=${VAULT_LICENSE_CI?}"
    fi

    # Pass explicit image tags for all installs so CI can pin a specific build.
    # For Enterprise the tags already carry the -ent suffix (appended above).
    # derive hashicorp/vault-enterprise automatically from the license secret.
    CHART_VALUES+=(--set injector.agentImage.tag="${INJECTOR_AGENT_VERSION}")
    CHART_VALUES+=(--set server.image.tag="${SERVER_VAULT_VERSION}")
    CHART_VALUES+=(--set csi.agent.image.tag="${CSI_AGENT_VERSION}")

    if [ "${ENT_TESTS}" != "true" ] || [ "${VAULT_REPOSITORY}" != "hashicorp/vault" ]; then
        # Pin the repository so CI can use a custom/mirror registry. For CE
        # installs this is always set; for Enterprise installs it is only set
        # when VAULT_REPOSITORY was explicitly overridden — otherwise the
        # chart helper auto-selects hashicorp/vault-enterprise from the
        # license secret.
        CHART_VALUES+=(--set injector.agentImage.repository="${VAULT_REPOSITORY}")
        CHART_VALUES+=(--set server.image.repository="${VAULT_REPOSITORY}")
        CHART_VALUES+=(--set csi.agent.image.repository="${VAULT_REPOSITORY}")
    fi

    SET_CHART_VALUES=${CHART_VALUES[*]}
    export SET_CHART_VALUES PRE_CHART_CMDS
}
