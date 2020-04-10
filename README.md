# MaaS Vault

This is a forked version of HashiCorp's Vault Helm Chart. It is forked for business continuity (should the original be deleted) and to adhere to the MPL-2.0 license of public disclosure of source changes.
This repository is used as a submodule in other repositories that install and setup Vault.

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

  * **Helm 3.0+** - This is the earliest version of Helm tested. It is possible
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

## Customizations

This Helm chart has been customized in the following ways:

### Support LoadBalancerIP Field

The Service spec in the **server-service.yaml** file now allows setting a
specific IP address when the Service type is set to `LoadBalancer` and a
**maas.lbAddress** value has been provided.
