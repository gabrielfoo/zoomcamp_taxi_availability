resource "google_compute_instance" "default" {
  name         = "kestra-instance"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      type  = "pd-balanced"
      size  = 10
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  # confirm it runs with: journalctl -u google-startup-scripts.service : https://cloud.google.com/compute/docs/instances/startup-scripts/linux#viewing-output
  metadata_startup_script = templatefile("${path.module}/instance_startup_scripts/startup-script.sh.tpl", {
    bucket_name              = google_storage_bucket.bucket.name
    kestra_setup_script      = google_storage_bucket_object.kestra_setup_script.name
    kestra_dockerfile_script = google_storage_bucket_object.kestra_dockerfile_script.name
    kestra_app_script        = google_storage_bucket_object.kestra_app_script.name
  })

  tags = ["kestra", "https-server"]

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_storage_bucket_object.kestra_setup_script,
    google_storage_bucket_object.kestra_dockerfile_script,
    google_storage_bucket_object.kestra_app_script
  ]

  provisioner "local-exec" {
    command = <<-EOT
      python ${path.module}/terraform_helper_scripts/check_instance_ready.py ${self.network_interface.0.access_config.0.nat_ip}
    EOT
  }
}

resource "google_compute_firewall" "default" {
  name      = "kestra-ui-port"
  network   = "default"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8080", "8081"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kestra", "https-server"]

}
