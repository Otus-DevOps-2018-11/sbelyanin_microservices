provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_project_metadata" "ssh-keys" {
  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance" "docker-host" {
  name         = "docker-host-${count.index}"
  count        = "${var.node_count}"
  machine_type = "g1-small"
  zone         = "${var.region}-${var.zone}"

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  tags = ["docker-machine", "reddit-app"]

  network_interface {
    network       = "default"
    access_config = {}
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_firewall" "docker-machines" {
  name    = "allow-docker-machines"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2376"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["docker-machines"]
}

resource "google_compute_firewall" "reddit-app" {
  name    = "allow-reddit-app"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}
