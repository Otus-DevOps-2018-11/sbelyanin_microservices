provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}


resource "google_container_cluster" "primary" {
  name   = "kube-gke-cluster"
  zone = "${var.region}-${var.zone}"
  initial_node_count = 2

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }


  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = true
    }

    kubernetes_dashboard {
      disabled = "false"
    }  
  }



  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "kube-node-pool"
  zone       = "${var.region}-${var.zone}"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}


resource "google_compute_firewall" "firewall-kub" {
  name    = "ingres-trafic"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
  source_ranges = ["0.0.0.0/0"]
}



# The following outputs allow authentication and connectivity to the GKE Cluster
# by using certificate-based authentication.
output "client_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}

