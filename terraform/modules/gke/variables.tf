variable "k8s_version" {
  default     = "1.10.5-gke.4"
  description = "The K8S version to use for both master and nodes."
}

variable "project" {
  description = <<EOF
Google Cloud Project to launch resources in. This project must have GKE
enabled and billing activated.
EOF
}

variable "zone" {
  default     = "us-central1-a"
  description = "The zone to launch all the GKE nodes in."
}
