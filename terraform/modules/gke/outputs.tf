output "cluster_id" {
  value = "${google_container_cluster.cluster.id}"
  depends_on = ["null_resource.kubectl"]
}
