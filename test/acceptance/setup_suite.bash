#!/usr/bin/env bats

setup_suite() {
    local INJECTOR_AGENT_VERSION SERVER_VAULT_VERSION CSI_AGENT_VERSION
    if [ -z "${VAULT_VERSION}" ]; then
        INJECTOR_AGENT_VERSION=$(yq -r '.injector.agentImage.tag' values.yaml)
        SERVER_VAULT_VERSION=$(yq -r '.server.image.tag' values.yaml)
        CSI_AGENT_VERSION=$(yq -r '.csi.image.tag' values.yaml)
    else
        INJECTOR_AGENT_VERSION=${VAULT_VERSION}
        SERVER_VAULT_VERSION=${VAULT_VERSION}
        CSI_AGENT_VERSION=${VAULT_VERSION}
    fi

    if [ -z ${ENT_TESTS+x} ]; then
        SERVER_VAULT_VERSION="${SERVER_VAULT_VERSION}-ent"
        ${VAULT_LICENSE_CI:?      "VAULT_LICENSE_CI must be set"}
    fi
    export INJECTOR_AGENT_VERSION SERVER_VAULT_VERSION CSI_AGENT_VERSION
}
