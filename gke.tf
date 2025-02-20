# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


# GKE cluster
data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.30."
}

resource "google_container_cluster" "primary" {
  name     = "my-takehome-cluster"
  location = var.region
  deletion_protection = false

  node_locations = [
    "us-central1-a",
  ]

  monitoring_config {
	enable_components = []     ## see discussion here: https://github.com/hashicorp/terraform-provider-google/issues/15056
	managed_prometheus {
		enabled = false
	}
	advanced_datapath_observability_config {
		enable_metrics = false
		enable_relay = false
	}
  }

  logging_config {
	enable_components = []
  }

  # to save time during TF runs, I leave this false, then later resize the default pool to 0 via the UI
  remove_default_node_pool = false
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-nodes"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  version = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]

  node_count = 4
  autoscaling {
	min_node_count = "4"
	max_node_count = "4"
  }
  # max_pods_per_node = "0"

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
	  "https://www.googleapis.com/auth/devstorage.read_only",
	  "https://www.googleapis.com/auth/service.management.readonly",
	  "https://www.googleapis.com/auth/servicecontrol",
	  "https://www.googleapis.com/auth/trace.append"
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["node-group", "primary-nodes"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_node_pool" "big_nodes" {
  name       = "big-nodes"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  version = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]

  node_count = 1
  autoscaling {
	min_node_count = "1"
	max_node_count = "1"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
	  "https://www.googleapis.com/auth/devstorage.read_only",
	  "https://www.googleapis.com/auth/service.management.readonly",
	  "https://www.googleapis.com/auth/servicecontrol",
	  "https://www.googleapis.com/auth/trace.append"
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-4"
    tags         = ["node-group", "big-nodes"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}