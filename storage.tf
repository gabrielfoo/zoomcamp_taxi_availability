resource "google_storage_bucket" "bucket" {
  name                     = var.bucket_name
  location                 = var.region
  force_destroy            = true
  public_access_prevention = "inherited"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 14
    }
  }
}

resource "google_storage_bucket_object" "dataproc_folder" {
  name    = "dataproc/"
  content = "Not really a directory, but it's empty."
  bucket  = google_storage_bucket.bucket.name
}

resource "google_storage_bucket_object" "dataproc_script" {
  name         = "${google_storage_bucket_object.dataproc_folder.name}${var.dataproc_script}"
  source       = "${var.dataproc_folder}${var.dataproc_script}"
  content_type = "text/plain"
  bucket       = google_storage_bucket.bucket.name
}

resource "google_storage_bucket_object" "kestra_setup_folder" {
  name    = "kestra/"
  content = "Not really a directory, but it's empty."
  bucket  = google_storage_bucket.bucket.name
}

resource "google_storage_bucket_object" "kestra_setup_script" {
  name         = "${google_storage_bucket_object.kestra_setup_folder.name}docker-compose.yml"
  source       = "./kestra/setup/docker-compose.yml"
  content_type = "text/plain"
  bucket       = google_storage_bucket.bucket.name
}

resource "google_storage_bucket_object" "kestra_dockerfile_script" {
  name         = "${google_storage_bucket_object.kestra_setup_folder.name}Dockerfile.kestra"
  source       = "./kestra/setup/Dockerfile.kestra"
  content_type = "text/plain"
  bucket       = google_storage_bucket.bucket.name
}

resource "google_storage_bucket_object" "kestra_app_script" {
  name         = "${google_storage_bucket_object.kestra_setup_folder.name}application.yaml"
  source       = "./kestra/setup/application.yaml"
  content_type = "text/plain"
  bucket       = google_storage_bucket.bucket.name
}