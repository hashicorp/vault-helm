locals {
  service_account_path = "${path.module}/service-account.yaml"
}

resource "null_resource" "service_account" {
  triggers {
    cluster_id = "${var.trigger}"
  }

  provisioner "local-exec" {
    command = <<EOF
kubectl apply -f '${local.service_account_path}'
helm init --service-account helm
EOF
  }
}
