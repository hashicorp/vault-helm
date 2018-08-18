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
download this repository and unpack it into a directory. Then, the chart can
be installed directly:

    helm install ./charts/consul

Please see the many options supported in the `./charts/consul/values.yaml`
file. These are also fully documented directly on the
[Consul website](https://www.consul.io/docs/).

## Testing

The Helm charts are tested in two forms: [Bats](https://github.com/bats-core/bats-core)
tests and `helm test` tests. The Bats tests test changing Helm chart values and
the effect on the install. The `helm test` tests verify that a deployed chart
appears healthy.

To run the Bats test: `kubectl` must be configured locally to be authenticated
to a running Kubernetes cluster with Helm installed. With that in place,
just run bats:

    bats ./charts/consul/test

If the tests fail, deployed resources in the Kubernetes cluster may not
be properly cleaned up. We recommend recycling the Kubernetes cluster to
start from a clean slate.

**Note:** There is a Terraform configuration in the
[terraform/ directory](https://github.com/hashicorp/consul-k8s/tree/master/terraform)
that can be used to quickly bring up a GKE cluster and configure
`kubectl` and `helm` locally. This can be used to quickly spin up a test
cluster.
