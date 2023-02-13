# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "cluster_id" {
  value = "${google_container_cluster.cluster.id}"
}

output "cluster_name" {
  value = "${google_container_cluster.cluster.name}"
}
