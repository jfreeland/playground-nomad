job "registry" {
  datacenters = ["dc1"]

  group "registry" {
    task "server" {
      driver = "docker"

      config {
        image = "registry:2"
        ports = ["registry"]
      }
    }
    network {
      port "registry" {
        static = "5000"
      }
    }
  }
}
