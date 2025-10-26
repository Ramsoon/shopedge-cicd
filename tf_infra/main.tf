terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# GKE Cluster
resource "google_container_cluster" "shopedgedge" {
  name     = "shopedgedge-cluster"
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Remove explicit CIDR blocks - let GCP auto-assign
  ip_allocation_policy {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    # Remove explicit master_ipv4_cidr_block or use a different one
    master_ipv4_cidr_block = "172.17.16.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "public"
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  #deletion_protection = false
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "shopedgedge-node-pool"
  location   = var.region
  cluster    = google_container_cluster.shopedgedge.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = 30

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "shopedgedge-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "shopedgedge-subnet"
  ip_cidr_range = "10.200.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id

  # secondary IP range for pods and services
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.2.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.3.0.0/16"
  }
}

# Artifact Registry
resource "google_artifact_registry_repository" "shopedgedge" {
  provider      = google-beta
  location      = var.region
  repository_id = "shopedgedge"
  description   = "Docker repository for ShopEdge"
  format        = "DOCKER"
}

# Service Accounts
resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions Service Account"
}

resource "google_service_account" "jenkins" {
  account_id   = "jenkins"
  display_name = "Jenkins Service Account"
}

# IAM Bindings
resource "google_project_iam_member" "github_actions_ar" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_gcr" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "jenkins_gke" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

# Outputs
output "cluster_name" {
  value = google_container_cluster.shopedgedge.name
}

output "cluster_region" {
  value = var.region
}

output "registry_url" {
  value = google_artifact_registry_repository.shopedgedge.repository_id
}

output "project_id" {
  value = var.project_id
}