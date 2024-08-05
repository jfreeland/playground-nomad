server {
  enabled = true
}

client {
  enabled = true
  network_interface = "enp0s1"

  host_volume "prometheus-config" {
    path      = "/mnt/nomad-jobs/prometheus"
    read_only = false
  }

  host_volume "grafana-dashboards" {
    path      = "/mnt/nomad-jobs/grafana/dashboards"
    read_only = false
  }

  host_volume "grafana-provisioner-dashboards" {
    path      = "/mnt/nomad-jobs/grafana/provisioning/dashboards"
    read_only = false
  }

  host_volume "grafana-provisioner-datasources" {
    path      = "/mnt/nomad-jobs/grafana/provisioning/datasources"
    read_only = false
  }
}
