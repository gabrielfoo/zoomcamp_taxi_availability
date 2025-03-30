provider "kestra" {
  url = "http://${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}:8080"
  username = var.kestra_user
  password = var.kestra_pw
}

resource "kestra_flow" "flows" {
  for_each   = fileset(path.module, "kestra/flows/**")
  flow_id    = "/${basename(each.value)}"
  namespace  = var.dataset_id
  content    = file(each.value)
  depends_on = [google_compute_instance.default]

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST http://${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}:8080/api/v1/executions/${var.dataset_id}/gcp_kv -u ${var.kestra_user}:${var.kestra_pw}
    EOT
  }
}
