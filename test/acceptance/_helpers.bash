# name_prefix returns the prefix of the resources within Kubernetes.
name_prefix() {
    printf "vault"
}

# chart_dir returns the directory for the chart
chart_dir() {
    echo ${BATS_TEST_DIRNAME}/../..
}

# helm_install installs the vault chart. This will source overridable
# values from the "values.yaml" file in this directory. This can be set
# by CI or other environments to do test-specific overrides. Note that its
# easily possible to break tests this way so be careful.
helm_install() {
    local values="${BATS_TEST_DIRNAME}/values.yaml"
    if [ ! -f "${values}" ]; then
        touch $values
    fi

    helm install -f ${values} \
        --name vault \
        ${BATS_TEST_DIRNAME}/../..
}

# helm_install_ha installs the vault chart using HA mode. This will source
# overridable values from the "values.yaml" file in this directory. This can be
# set by CI or other environments to do test-specific overrides. Note that its
# easily possible to break tests this way so be careful.
helm_install_ha() {
    local values="${BATS_TEST_DIRNAME}/values.yaml"
    if [ ! -f "${values}" ]; then
        touch $values
    fi

    helm install -f ${values} \
        --name vault \
        --set 'server.enabled=false' \
        --set 'serverHA.enabled=true' \
        ${BATS_TEST_DIRNAME}/../..
}

# wait for consul to be ready
wait_for_running_consul() {
    kubectl wait --for=condition=Ready --timeout=5m pod -l app=consul,component=client
}

wait_for_sealed_vault() {
    POD_NAME=$1

    check() {
        sealed_status=$(kubectl exec $1 -- vault status -format=json | jq -r '.sealed')
        if [ "$sealed_status" == "true" ]; then
            return 0
        fi
        return 1
    }

    for i in $(seq 60); do
        if check ${POD_NAME}; then
            echo "Vault on ${POD_NAME} is running."
            return
        fi

        echo "Waiting for Vault on ${POD_NAME} to be running..."
        sleep 2
    done

    echo "Vault on ${POD_NAME} never became running."
    return 1
}

# wait for a pod to be running
wait_for_running() {
    POD_NAME=$1

    check() {
        # This requests the pod and checks whether the status is running
        # and the ready state is true. If so, it outputs the name. Otherwise
        # it outputs empty. Therefore, to check for success, check for nonzero
        # string length.
        kubectl get pods $1 -o json | \
            jq -r 'select(
                .status.phase == "Running" and
                ([ .status.conditions[] | select(.type == "Ready" and .status == "False") ] | length) == 1
            ) | .metadata.namespace + "/" + .metadata.name'
    }

    for i in $(seq 60); do
        if [ -n "$(check ${POD_NAME})" ]; then
            echo "${POD_NAME} is ready."
            sleep 5
            return
        fi

        echo "Waiting for ${POD_NAME} to be ready..."
        sleep 2
    done

    echo "${POD_NAME} never became ready."
    return 1
}

wait_for_ready() {
    POD_NAME=$1

    check() {
        # This requests the pod and checks whether the status is running
        # and the ready state is true. If so, it outputs the name. Otherwise
        # it outputs empty. Therefore, to check for success, check for nonzero
        # string length.
        kubectl get pods $1 -o json | \
            jq -r 'select(
                .status.phase == "Running" and
                ([ .status.conditions[] | select(.type == "Ready" and .status == "True") ] | length) == 1
            ) | .metadata.namespace + "/" + .metadata.name'
    }

    for i in $(seq 60); do
        if [ -n "$(check ${POD_NAME})" ]; then
            echo "${POD_NAME} is ready."
            sleep 5
            return
        fi

        echo "Waiting for ${POD_NAME} to be ready..."
        sleep 2
    done

    echo "${POD_NAME} never became ready."
    return 1
}

wait_for_complete_job() {
	POD_NAME=$1

    check() {
        # This requests the pod and checks whether the status is running
        # and the ready state is true. If so, it outputs the name. Otherwise
        # it outputs empty. Therefore, to check for success, check for nonzero
        # string length.
        kubectl get job $1 -o json | \
            jq -r 'select(
                .status.succeeded == 1 
            ) | .metadata.namespace + "/" + .metadata.name'
    }

    for i in $(seq 60); do
        if [ -n "$(check ${POD_NAME})" ]; then
            echo "${POD_NAME} is complete."
            sleep 5
            return
        fi

        echo "Waiting for ${POD_NAME} to be complete..."
        sleep 2
    done

    echo "${POD_NAME} never completed."
    return 1
}
