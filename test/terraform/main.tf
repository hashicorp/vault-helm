provider "google" {
  project = "${var.project}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_container_cluster" "cluster" {
  name               = "consul-k8s-${random_id.suffix.dec}"
  project            = "${var.project}"
  enable_legacy_abac = true
  initial_node_count = 5
  zone               = "${var.zone}"
  min_master_version = "${var.k8s_version}"
  node_version       = "${var.k8s_version}"
}

