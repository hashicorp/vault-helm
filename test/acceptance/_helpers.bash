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

wait_for_ready() {
    NAME=$1
    kubectl wait --for condition=ready=true pod/${NAME?} --timeout=60s
    if [[ $? != 0 ]]
    then
        echo "pod/${NAME?} never became ready."
        exit 1
	fi
}

wait_for_not_ready() {
    NAME=$1
    kubectl wait --for condition=ready=false pod/${NAME?} --timeout=60s
    if [[ $? != 0 ]]
    then
        echo "pod/${NAME?} never became unready."
        exit 1
	fi
}

# wait for a pod to be ready
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
            sleep 10
            return
        fi

        echo "Waiting for ${POD_NAME} to be ready..."
        sleep 2
    done

    echo "${POD_NAME} never became ready."
    exit 1
}
