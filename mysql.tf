# ==========================================
# Кластер MySQL (Prestable, Intel Broadwell, 50% CPU, 20 GB)
# ==========================================
resource "yandex_mdb_mysql_cluster" "mysql_cluster" {
  name        = "mysql-cluster"
  description = "MySQL cluster for Netology homework"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.main.id
  version     = "8.0"

  resources {
    resource_preset_id = "b1.medium"  # Intel Broadwell, 50% CPU
    disk_size          = 20           # 20 GB
    disk_type_id       = "network-ssd"
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SUN"
    hour = 3
  }

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  deletion_protection = true

  access {
    data_lens     = false
    web_sql       = true
    data_transfer = false
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.mysql_a.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.mysql_b.id
    assign_public_ip = false
  }

  security_group_ids = [yandex_vpc_security_group.mysql_sg.id]
}

# ==========================================
# База данных и пользователь
# ==========================================
resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql_cluster.id
  name       = var.mysql_db_name
}

resource "yandex_mdb_mysql_user" "netology_user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql_cluster.id
  name       = var.mysql_user_login
  password   = var.mysql_user_password

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }
}

output "mysql_cluster_id" {
  value = yandex_mdb_mysql_cluster.mysql_cluster.id
}

output "mysql_fqdn" {
  value = yandex_mdb_mysql_cluster.mysql_cluster.host[0].fqdn
}
