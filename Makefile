TEST_IMAGE?=vault-helm-test
GOOGLE_CREDENTIALS?=vault-helm-test.json
CLOUDSDK_CORE_PROJECT?=vault-helm-dev-246514
# set to run a single test - e.g acceptance/server-ha-enterprise-dr.bats
ACCEPTANCE_TESTS?=acceptance

# Generate json schema for chart values. See test/README.md for more details.
values-schema:
	helm schema-gen values.yaml > values.schema.json

test-image:
	@docker build --rm -t $(TEST_IMAGE) -f $(CURDIR)/test/docker/Test.dockerfile $(CURDIR)

test-unit:
	@docker run -it -v ${PWD}:/helm-test $(TEST_IMAGE) bats /helm-test/test/unit

test-bats: test-unit test-acceptance

test: test-image test-bats

# run acceptance tests on GKE
# set google project/credential vars above
test-acceptance:
	@docker run -it -v ${PWD}:/helm-test \
	-e GOOGLE_CREDENTIALS=${GOOGLE_CREDENTIALS} \
	-e CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT} \
	-e KUBECONFIG=/helm-test/.kube/config \
	-w /helm-test \
	$(TEST_IMAGE) \
	make acceptance
	
# destroy GKE cluster using terraform
test-destroy:
	@docker run -it -v ${PWD}:/helm-test \
	-e GOOGLE_CREDENTIALS=${GOOGLE_CREDENTIALS} \
	-e CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT} \
	-w /helm-test \
	$(TEST_IMAGE) \
	make destroy-cluster

# provision GKE cluster using terraform
test-provision:
	@docker run -it -v ${PWD}:/helm-test \
	-e GOOGLE_CREDENTIALS=${GOOGLE_CREDENTIALS} \
	-e CLOUDSDK_CORE_PROJECT=${CLOUDSDK_CORE_PROJECT} \
	-e KUBECONFIG=/helm-test/.kube/config \
	-w /helm-test \
	$(TEST_IMAGE) \
	make provision-cluster

# this target is for running the acceptance tests
# it is run in the docker container above when the test-acceptance target is invoked
acceptance:
	gcloud auth activate-service-account --key-file=${GOOGLE_CREDENTIALS}
	bats test/${ACCEPTANCE_TESTS}

# this target is for provisioning the GKE cluster
# it is run in the docker container above when the test-provision target is invoked
provision-cluster:
	gcloud auth activate-service-account --key-file=${GOOGLE_CREDENTIALS}
	terraform init test/terraform
	terraform apply -var project=${CLOUDSDK_CORE_PROJECT} -var init_cli=true -auto-approve test/terraform

# this target is for removing the GKE cluster
# it is run in the docker container above when the test-destroy target is invoked
destroy-cluster:
	terraform destroy -auto-approve

.PHONY: values-schema test-image test-unit test-bats test test-acceptance test-destroy test-provision acceptance provision-cluster destroy-cluster
