module "gke" {
  source  = "./modules/gke"
  project = "${var.project}"
}

module "helm" {
  source  = "./modules/helm"
  trigger = "${module.gke.cluster_id}"
}
