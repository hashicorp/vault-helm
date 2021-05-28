#!/usr/bin/env bats

load _helpers

setup_file() {
    cd `chart_dir`
    export VERIFY_OUTPUT="/$BATS_RUN_TMPDIR/verify.json"
    export CHART_VOLUME=vault-helm-chart-src
    # Note: currently `latest` is the only tag available in the chart-verifier repo.
    local IMAGE="quay.io/redhat-certification/chart-verifier:latest"
    # chart-verifier requires an openshift version if a cluster isn't available
    local OPENSHIFT_VERSION="4.7"
    local DISABLED_TESTS="chart-testing"

    local run_cmd="chart-verifier"
    local chart_src="."

    if [ ! -e $USE_DOCKER ]; then
        chart_src="/chart"
        # Create a dummy container which will hold a volume with chart source
        docker create -v $chart_src --name $CHART_VOLUME alpine:3 /bin/true
        # Copy the chart source into this volume
        docker cp . $CHART_VOLUME:$chart_src
        # Make sure we have the latest version of chart-verifier
        docker pull $IMAGE
        # Start chart-verifier using this volume
        run_cmd="docker run --rm --volumes-from $CHART_VOLUME $IMAGE"
    fi

    $run_cmd verify $chart_src \
      --output json \
      --openshift-version $OPENSHIFT_VERSION \
      --disable $DISABLED_TESTS 2>&1 | tee $VERIFY_OUTPUT
}

teardown_file() {
    if [ ! -e $USE_DOCKER ]; then
        docker rm $CHART_VOLUME
    fi
}

@test "has-kubeversion" {
    check_result has-kubeversion
}

@test "is-helm-v3" {
    check_result is-helm-v3
}

@test "not-contains-crds" {
    check_result not-contains-crds
}

@test "helm-lint" {
    check_result helm-lint
}

@test "not-contain-csi-objects" {
    check_result not-contain-csi-objects
}

@test "has-readme" {
    check_result has-readme
}

@test "contains-values" {
    check_result contains-values
}

@test "contains-values-schema" {
    check_result contains-values-schema
}

@test "contains-test" {
    check_result contains-test
}

@test "chart-testing" {
    skip "Skipping since this test requires a kubernetes/openshift cluster"
    check_result chart-testing
}

@test "images-are-certified" {
    skip "Skipping until this has been addressed"
    check_result images-are-certified
}
