#!/usr/bin/env bats

load _helpers

setup_file() {
    cd `chart_dir`
    export VERIFY_OUTPUT="/$BATS_RUN_TMPDIR/verify.json"
    export CHART_VOLUME=vault-helm-chart-src
    local IMAGE="quay.io/redhat-certification/chart-verifier:1.2.1"
    # chart-verifier requires an openshift version if a cluster isn't available
    local OPENSHIFT_VERSION="4.8"
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
        run_cmd="docker run --rm --volumes-from $CHART_VOLUME -w $chart_src $IMAGE"
    fi

    $run_cmd verify $chart_src \
      --output json \
      --openshift-version $OPENSHIFT_VERSION \
      --disable $DISABLED_TESTS \
      --chart-values values.openshift.yaml 2>&1 | tee $VERIFY_OUTPUT
}

teardown_file() {
    if [ ! -e $USE_DOCKER ]; then
        docker rm $CHART_VOLUME
    fi
}

@test "has-kubeversion" {
    check_result v1.0/has-kubeversion
}

@test "is-helm-v3" {
    check_result v1.0/is-helm-v3
}

@test "not-contains-crds" {
    check_result v1.0/not-contains-crds
}

@test "helm-lint" {
    check_result v1.0/helm-lint
}

@test "not-contain-csi-objects" {
    check_result v1.0/not-contain-csi-objects
}

@test "has-readme" {
    check_result v1.0/has-readme
}

@test "contains-values" {
    check_result v1.0/contains-values
}

@test "contains-values-schema" {
    check_result v1.0/contains-values-schema
}

@test "contains-test" {
    check_result v1.0/contains-test
}

@test "images-are-certified" {
    check_result v1.0/images-are-certified
}

@test "chart-testing" {
    skip "Skipping since this test requires a kubernetes/openshift cluster"
    check_result v1.0/chart-testing
}
