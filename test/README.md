# Running Vault Helm Acceptance tests

The Makefile at the top level of this repo contains a few target that should help with running acceptance tests in your own GKE instance.

* Set the GOOGLE_CREDENTIALS and CLOUDSDK_CORE_PROJECT variables at the top of the file. GOOGLE_CREDENTIALS should contain the local path to your Google Cloud Platform account credentials in JSON format. CLOUDSDK_CORE_PROJECT should be set to the ID of your GCP project.
* Run `make test-image` to create the docker image (with dependencies installed) that will be re-used in the below steps.
* Run `make test-provision` to provision the GKE cluster using terraform.
* Run `make test-acceptance` to run the acceptance tests in this already provisioned cluster.
* You can choose to only run certain tests by setting the ACCEPTANCE_TESTS variable and re-running the above target.
* Run `make test-destroy` when you have finished testing and want to tear-down and remove the cluster.