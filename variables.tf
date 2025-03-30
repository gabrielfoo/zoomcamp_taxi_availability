variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "zoomcamp-uniqueid-1337"
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "For Compute Engine"
  type        = string
  default     = "us-central1-a"
}

variable "bucket_name" {
  description = "Storage Bucket"
  type        = string
  default     = "zoomcamp_4_2025_qwik"
}

variable "dataset_id" {
  description = "Dataset ID"
  type        = string
  default     = "zoomcamp_dataset"
}

variable "dataproc_script" {
  description = "dataproc file name on computer"
  type        = string
  default     = "dataproc_wd.py"
}

variable "dataproc_folder" {
  description = "dataproc folder name on local computer"
  type        = string
  default     = "./spark/"
}

variable "kestra_user" {
  description = "Kestra user"
  type        = string
  default     = "me@google.com"
}

variable "kestra_pw" {
  description = "Kestra basic auth password"
  type        = string
  default     = "kestra"
}
