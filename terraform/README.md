# Terraform

This folder contains a Terraform configuration that can be used to setup
an example cluster. These are not meant to be production ready modules for
using Consul with Kubernetes.

The pre-requisites for Terraform are:

  * Google Cloud authentication. See [Google Application Default Credentials](https://cloud.google.com/docs/authentication/production). You may also reuse your `gcloud` credentials by exposing them as application defaults by running `gcloud auth application-default login`.
  * `gcloud` installed and configured locally with GKE components.
  * The following programs available on the PATH: `kubectl`, `helm`, `grep`, `xargs`.

With that available, run the following:

```
$ terraform init
$ terraform apply
```

The apply will ask you for the name of the project to setup the cluster.
After this, everything will be setup, your local `kubectl` credentials will
be configured, and you may use `helm` directly.

