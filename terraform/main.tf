provider "yandex" {
  version                  = 0.35
  service_account_key_file = "../yc-svc-key.json"
  cloud_id                 = "b1gl05ddrl6bfdapqu15"
  folder_id                = "b1gd4td7jk7gdlac0laf"
  zone                     = "ru-central1-a"
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = "fd88ba04hjbah1vgtcm4"
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "e9b4gc5qqhfpoe63kt9p"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
}
