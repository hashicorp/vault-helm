# Consul Helm Chart

This repository contains the official HashiCorp Helm chart for installing
and configuring Consul on Kubernetes. This chart supports multiple use
cases of Consul on Kubernetes depending on the values provided.

Please see the [consul-k8s project](https://github.com/hashicorp/consul-k8s)
for the various ways that Consul integrates with Kubernetes. This Helm chart
installs and configures `consul-k8s` in some cases.

## Prerequisites

To use the charts here, [Helm](https://helm.sh/) must be installed in your
Kubernetes cluster. Setting up Kubernetes and Helm and is outside the scope
of this README. Please refer to the Kubernetes and Helm documentation.

## Usage

For now, we do not host a Chart repository. To use the charts, you must
download this repository and unpack it into a directory. Assuming this
repository was unpacked into the directory `consul-helm`, the chart can
then be installed directly:

    helm install ./consul-helm

Please see the many options supported in the `values.yaml`
file. These are also fully documented directly on the
[Consul website](https://www.consul.io/docs/).

## Testing

The Helm chart ships with both unit and acceptance tests.

The unit tests don't require any active Kubernetes cluster and complete
very quickly. These should be used for fast feedback during development.
The acceptance tests require a Kubernetes cluster with a configured `kubectl`.
Both require [Bats](https://github.com/bats-core/bats-core) and `helm` to
be installed and available on the CLI.

To run the unit tests:

    bats ./test/unit

To run the acceptance tests:

    bats ./test/acceptance

If the acceptance tests fail, deployed resources in the Kubernetes cluster
may not be properly cleaned up. We recommend recycling the Kubernetes cluster to
start from a clean slate.

**Note:** There is a Terraform configuration in the
[test/terraform/ directory](https://github.com/hashicorp/consul-helm/tree/master/test/terraform)
that can be used to quickly bring up a GKE cluster and configure
`kubectl` and `helm` locally. This can be used to quickly spin up a test
cluster.
