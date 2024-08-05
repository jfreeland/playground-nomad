datacenter = "dc1"
data_dir = "/opt/consul"
client_addr = "0.0.0.0"
ui_config {
  enabled = true
}
server = true
bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"192.168.0.0/16\" | attr \"address\" }}"
