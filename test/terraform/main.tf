locals {
  service_account_path = "${path.module}/service-account.yaml"
}

provider "google" {
  project = "${var.project}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "google_container_engine_versions" "main" {
  zone = "${var.zone}"
}

resource "google_container_cluster" "cluster" {
  name               = "consul-k8s-${random_id.suffix.dec}"
  project            = "${var.project}"
  enable_legacy_abac = true
  initial_node_count = 5
  zone               = "${var.zone}"
  min_master_version = "${data.google_container_engine_versions.main.latest_master_version}"
  node_version       = "${data.google_container_engine_versions.main.latest_node_version}"
}

resource "null_resource" "kubectl" {
  count = "${var.init_cli ? 1 : 0 }"

  triggers {
    cluster = "${google_container_cluster.cluster.id}"
  }

  # On creation, we want to setup the kubectl credentials. The easiest way
  # to do this is to shell out to gcloud.
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials --zone=${var.zone} ${google_container_cluster.cluster.name}"
  }

  # On destroy we want to try to clean up the kubectl credentials. This
  # might fail if the credentials are already cleaned up or something so we
  # want this to continue on failure. Generally, this works just fine since
  # it only operates on local data.
  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"
    command    = "kubectl config get-clusters | grep ${google_container_cluster.cluster.name} | xargs -n1 kubectl config delete-cluster"
  }

  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"
    command    = "kubectl config get-contexts | grep ${google_container_cluster.cluster.name} | xargs -n1 kubectl config delete-context"
  }
}

resource "null_resource" "helm" {
  count = "${var.init_cli ? 1 : 0 }"
  depends_on = ["null_resource.kubectl"]

  triggers {
    cluster = "${google_container_cluster.cluster.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
kubectl apply -f '${local.service_account_path}'
helm init --service-account helm
EOF
  }
}
