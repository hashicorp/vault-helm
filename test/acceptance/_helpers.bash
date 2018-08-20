# name_prefix returns the prefix of the resources within Kubernetes.
name_prefix() {
    printf "consul"
}

# helm_install installs the Consul chart.
helm_install() {
    helm install --name consul --wait ${BATS_TEST_DIRNAME}/..
}

# helm_delete deletes the Consul chart and all resources.
helm_delete() {
    helm delete --purge consul
    kubectl delete --all pvc
}

# wait for a pod to be ready
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

    for i in $(seq 30); do
        if [ -n "$(check ${POD_NAME})" ]; then
            echo "${POD_NAME} is ready."
            return
        fi

        echo "Waiting for ${POD_NAME} to be ready..."
        sleep 2
    done

    echo "${POD_NAME} never became ready."
    exit 1
}
