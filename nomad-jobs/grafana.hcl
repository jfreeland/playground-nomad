job "grafana" {
  datacenters = ["dc1"]
  type        = "service"

  group "grafana" {
    count = 1

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:11.1.2"
        ports = ["http"]
      }

      service {
        name = "grafana"
        port = "http"
      }

      env {
        GF_AUTH_DISABLE_LOGIN_FORM = "true"
        GF_AUTH_ANONYMOUS_ENABLED = "true"
        GD_AUTH_ANONYMOUS_ORG_ROLE = "Admin"
      }

      volume_mount {
        volume = "grafana-dashboards"
        destination = "/var/lib/grafana/dashboards"
        read_only = false
      }

      volume_mount {
        volume = "grafana-provisioner-dashboards"
        destination = "/etc/grafana/provisioning/dashboards"
        read_only = false
      }

      volume_mount {
        volume = "grafana-provisioner-datasources"
        destination = "/etc/grafana/provisioning/datasources"
        read_only = false
      }
    }

    network {
      port "http" {
        static = 3000
      }
    }

    volume "grafana-dashboards" {
      type      = "host"
      read_only = false
      source    = "grafana-dashboards"
    }

    volume "grafana-provisioner-dashboards" {
      type      = "host"
      read_only = false
      source    = "grafana-provisioner-dashboards"
    }

    volume "grafana-provisioner-datasources" {
      type      = "host"
      read_only = false
      source    = "grafana-provisioner-datasources"
    }
  }
}
