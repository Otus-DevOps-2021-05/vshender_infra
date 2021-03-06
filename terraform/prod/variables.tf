variable service_account_key_file {
  description = "Path to the Yandex.Cloud service account key file"
}

variable cloud_id {
  # Описание переменной
  description = "Cloud"
}

variable folder_id {
  description = "Folder"
}

variable region_id {
  description = "Region"
  default     = "ru-central1"
}

variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}
