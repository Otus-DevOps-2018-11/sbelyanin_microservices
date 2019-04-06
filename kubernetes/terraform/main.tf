provider "google" {
  version = "1.20.0"
  project = "${var.project}"
  region  = "${var.region}"
}


resource "google_container_cluster" "primary" {
  name   = "kube-gke-cluster"
  zone = "${var.region}-${var.zone}"
#  initial_node_count = 2

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = "false"
    }  
  }

#  node_config {
#    machine_type = "n1-standard-1"
#    image_type   = "COS"
#    disk_type    = "pd-standard"
#    disk_size_gb = "20"

#    oauth_scopes = [
#      "https://www.googleapis.com/auth/compute",
#      "https://www.googleapis.com/auth/devstorage.read_only",
#      "https://www.googleapis.com/auth/logging.write",
#      "https://www.googleapis.com/auth/monitoring",
#      "https://www.googleapis.com/auth/servicecontrol",
#      "https://www.googleapis.com/auth/service.management.readonly",
#      "https://www.googleapis.com/auth/trace.append",
#    ]
#  }


  node_pool {
    name       = "more-pool"
    node_count = "3"
    node_config {
      machine_type = "n1-standard-2"
      disk_size_gb = "35"
    }
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

