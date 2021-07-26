resource "yandex_vpc_network" "app_network" {
  name = "app-network"
}

resource "yandex_vpc_subnet" "app_subnet" {
  name           = "app-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.app_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
