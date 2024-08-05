job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  group "prometheus" {
    count = 1

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.53.1"
        ports = ["http"]
      }

      service {
        name = "prometheus"
        port = "http"
      }

      volume_mount {
        volume = "prometheus-config"
        destination = "/etc/prometheus"
        read_only = false
      }
    }

    network {
      port "http" {
        static = 9090
      }
    }

    volume "prometheus-config" {
      type      = "host"
      read_only = false
      source    = "prometheus-config"
    }
  }
}
