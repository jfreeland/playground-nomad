job "helloworld" {
  datacenters = ["dc1"]

  group "frontend" {

    task "server" {
      driver = "docker"

      config {
        image = "joeyfreeland/helloworld:ok"
        ports = ["http"]
      }

      service {
        name = "helloworld"
        port = "http"
      }
    }

    network {
      port "http" {
        static = "8080"
      }
    }
  }
}
