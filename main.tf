terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
    kestra = {
      source  = "kestra-io/kestra"
      version = "0.21.1"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "my_dataset" {
  dataset_id                 = var.dataset_id
  project                    = var.project_id
  delete_contents_on_destroy = true
}

resource "google_project_service" "dataproc" {
  project = var.project_id
  service = "dataproc.googleapis.com"
}





