# GKE Cluster Setup

This module creates a GKE cluster for running and testing the Consul and
Kubernetes integrations. The GKE cluster is an opinionated setup and this
module is not meant to be a generic GKE module. This module also configures
`kubectl` credentials.

After this module completes, a GKE cluster is created and `kubectl` is
configured such that you can immediately verify the Kubernetes cluster:

    kubectl get componentstatus

**WARNING:** This module will create resources that cost money. This does
not use free tier resources.

## Requirements

  * Google Cloud authentication. See [Google Application Default Credentials](https://cloud.google.com/docs/authentication/production). You may also reuse your `gcloud` credentials by exposing them as application defaults by running `gcloud auth application-default login`.
  * `gcloud` installed and configured locally with GKE components and available on the PATH.
  * `kubectl` installed locally and available on the PATH.
  * A Google Cloud Project with GKE and billing activated.
  * Unix-like environment that supports piping, `grep`, and `xargs`.
