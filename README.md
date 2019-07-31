# Vault Helm Chart

This repository contains the official HashiCorp Helm chart for installing
and configuring Vault on Kubernetes. This chart supports multiple use
cases of Vault on Kubernetes depending on the values provided.

For full documentation on this Helm chart along with all the ways you can
use Vault with Kubernetes, please see the
[Vault and Kubernetes documentation](https://www.vaultproject.io/docs/platform/k8s/index.html).

## Prerequisites

To use the charts here, [Helm](https://helm.sh/) must be installed in your
Kubernetes cluster. Setting up Kubernetes and Helm and is outside the scope
of this README. Please refer to the Kubernetes and Helm documentation.

The versions required are:

  * **Helm 2.10+** - This is the earliest version of Helm tested. It is possible
    it works with earlier versions but this chart is untested for those versions.
  * **Kubernetes 1.9+** - This is the earliest version of Kubernetes tested.
    It is possible that this chart works with earlier versions but it is
    untested. Other versions verified are Kubernetes 1.10, 1.11.

## Usage

For now, we do not host a chart repository. To use the charts, you must
download this repository and unpack it into a directory. Either
[download a tagged release](https://github.com/hashicorp/vault-helm/releases) or
use `git checkout` to a tagged release.
Assuming this repository was unpacked into the directory `vault-helm`, the chart can
then be installed directly:

    helm install ./vault-helm

Please see the many options supported in the `values.yaml`
file. These are also fully documented directly on the
[Vault website](https://www.vaultproject.io/docs/platform/k8s/helm.html).

## Testing

The Helm chart ships with both unit and acceptance tests.

The unit tests don't require any active Kubernetes cluster and complete
very quickly. These should be used for fast feedback during development.
The acceptance tests require a Kubernetes cluster with a configured `kubectl`.

### Prequisites
* [Bats](https://github.com/bats-core/bats-core)
  ```bash
  brew install bats-core
  ```
* [yq](https://pypi.org/project/yq/)
  ```bash
  brew install python-yq
  ```
* [helm](https://helm.sh)
  ```bash
  brew install kubernetes-helm
  ```

### Running The Tests

To run the unit tests:

    bats ./test/unit

To run the acceptance tests:

    bats ./test/acceptance

If the acceptance tests fail, deployed resources in the Kubernetes cluster
may not be properly cleaned up. We recommend recycling the Kubernetes cluster to
start from a clean slate.

**Note:** There is a Terraform configuration in the
[`test/terraform/`](https://github.com/hashicorp/vault-helm/tree/master/test/terraform) directory
that can be used to quickly bring up a GKE cluster and configure
`kubectl` and `helm` locally. This can be used to quickly spin up a test
cluster for acceptance tests. Unit tests _do not_ require a running Kubernetes
cluster.

### Writing Unit Tests

Changes to the Helm chart should be accompanied by appropriate unit tests.

#### Formatting

- Put tests in the test file in the same order as the variables appear in the `values.yaml`.
- Start tests for a chart value with a header that says what is being tested, like this:
    ```
    #--------------------------------------------------------------------
    # annotations
    ```

- Name the test based on what it's testing in the following format (this will be its first line):
    ```
    @test "<section being tested>: <short description of the test case>" {
    ```

    When adding tests to an existing file, the first section will be the same as the other tests in the file.

#### Test Details

[Bats](https://github.com/bats-core/bats-core) provides a way to run commands in a shell and inspect the output in an automated way.
In all of the tests in this repo, the base command being run is [helm template](https://docs.helm.sh/helm/#helm-template) which turns the templated files into straight yaml output.
In this way, we're able to test that the various conditionals in the templates render as we would expect.

Each test defines the files that should be rendered using the `-x` flag, then it might adjust chart values by adding `--set` flags as well.
The output from this `helm template` command is then piped to [yq](https://pypi.org/project/yq/).
`yq` allows us to pull out just the information we're interested in, either by referencing its position in the yaml file directly or giving information about it (like its length).
The `-r` flag can be used with `yq` to return a raw string instead of a quoted one which is especially useful when looking for an exact match.

The test passes or fails based on the conditional at the end that is in square brackets, which is a comparison of our expected value and the output of  `helm template` piped to `yq`.

The `| tee /dev/stderr ` pieces direct any terminal output of the `helm template` and `yq` commands to stderr so that it doesn't interfere with `bats`.

#### Test Examples

Here are some examples of common test patterns:

- Check that a value is disabled by default

    ```
    @test "ui/Service: no type by default" {
      cd `chart_dir`
      local actual=$(helm template \
          -x templates/ui-service.yaml  \
          . | tee /dev/stderr |
          yq -r '.spec.type' | tee /dev/stderr)
      [ "${actual}" = "null" ]
    }
    ```

    In this example, nothing is changed from the default templates (no `--set` flags), then we use `yq` to retrieve the value we're checking, `.spec.type`.
    This output is then compared against our expected value (`null` in this case) in the assertion `[ "${actual}" = "null" ]`.


- Check that a template value is rendered to a specific value
    ```
    @test "ui/Service: specified type" {
      cd `chart_dir`
      local actual=$(helm template \
          -x templates/ui-service.yaml  \
          --set 'ui.serviceType=LoadBalancer' \
          . | tee /dev/stderr |
          yq -r '.spec.type' | tee /dev/stderr)
      [ "${actual}" = "LoadBalancer" ]
    }
    ```

    This is very similar to the last example, except we've changed a default value with the `--set` flag and correspondingly changed the expected value.

- Check that a template value contains several values
    ```
	@test "server/standalone-StatefulSet: custom resources" {
	  cd `chart_dir`
	  local actual=$(helm template \
		  -x templates/server-statefulset.yaml  \
		  --set 'server.standalone.enabled=true' \
		  --set 'server.resources.requests.memory=256Mi' \
		  --set 'server.resources.requests.cpu=250m' \
		  . | tee /dev/stderr |
		  yq -r '.spec.template.spec.containers[0].resources.requests.memory' | tee /dev/stderr)
	  [ "${actual}" = "256Mi" ]

	  local actual=$(helm template \
		  -x templates/server-statefulset.yaml  \
		  --set 'server.standalone.enabled=true' \
		  --set 'server.resources.limits.memory=256Mi' \
		  --set 'server.resources.limits.cpu=250m' \
		  . | tee /dev/stderr |
		  yq -r '.spec.template.spec.containers[0].resources.limits.memory' | tee /dev/stderr)
	  [ "${actual}" = "256Mi" ]
    ```

    *Note:* If testing more than two conditions, it would be good to separate the `helm template` part of the command from the `yq` sections to reduce redundant work.

- Check that an entire template file is not rendered
    ```
    @test "syncCatalog/Deployment: disabled by default" {
      cd `chart_dir`
      local actual=$(helm template \
          -x templates/server-statefulset.yaml  \
          --set 'global.enabled=false' \
          . | tee /dev/stderr |
          yq 'length > 0' | tee /dev/stderr)
      [ "${actual}" = "false" ]
    }
    ```
    Here we are check the length of the command output to see if the anything is rendered.
    This style can easily be switched to check that a file is rendered instead.
