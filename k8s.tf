# ==========================================
# 1. Сервисные аккаунты
# ==========================================
resource "yandex_iam_service_account" "k8s_sa" {
  name        = "k8s-cluster-sa"
  description = "Service account for Kubernetes cluster master"
}

resource "yandex_iam_service_account" "k8s_node_sa" {
  name        = "k8s-node-sa"
  description = "Service account for Kubernetes nodes"
}

# ==========================================
# 2. Назначение ролей
# ==========================================
resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_clusters_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_vpc_public_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_kms_encrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_sa.id}"
}

# ==========================================
# 3. Кластер Kubernetes (Zonal, зона B для стабильности)
# ==========================================
resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name       = "k8s-cluster"
  network_id = yandex_vpc_network.main.id

  master {
    public_ip = true

    zonal {
      zone      = yandex_vpc_subnet.k8s_b.zone
      subnet_id = yandex_vpc_subnet.k8s_b.id
    }

    # КРИТИЧЕСКИ ВАЖНО: Явная привязка группы безопасности
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]

    maintenance_policy {
      auto_upgrade = true
      maintenance_window {
        start_time = "03:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_node_sa.id

  # REGULAR стабильнее при создании
  release_channel         = "REGULAR"
  network_policy_provider = "CALICO"

  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s_encryption_key.id
  }

  # Ждём применения всех ролей и создания самой группы безопасности
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_sa_editor,
    yandex_resourcemanager_folder_iam_member.k8s_clusters_agent,
    yandex_resourcemanager_folder_iam_member.k8s_vpc_public_admin,
    yandex_resourcemanager_folder_iam_member.k8s_kms_encrypter,
    yandex_resourcemanager_folder_iam_member.k8s_node_sa_puller,
    yandex_vpc_security_group.k8s_sg
  ]

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

# ==========================================
# 4. Группа узлов с автомасштабированием (3-6) в зоне B
# ==========================================
resource "yandex_kubernetes_node_group" "k8s_nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group"

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = 2
      memory        = 4
      core_fraction = 100
    }

    boot_disk {
      type = "network-ssd"
      size = 30
    }

    scheduling_policy {
      preemptible = false
    }

    network_interface {
      nat                = true
      subnet_ids         = [yandex_vpc_subnet.k8s_b.id]
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    }

    metadata = {
      ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
    }
  }

  scale_policy {
    auto_scale {
      min     = 3
      max     = 6
      initial = 3
    }
  }

  # Ограничение Yandex Cloud: auto_scale работает только в одной зоне
  allocation_policy {
    location {
      zone = "ru-central1-b"
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "20m"
  }
}

# ==========================================
# Outputs
# ==========================================
output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s_cluster.id
}

output "k8s_cluster_endpoint" {
  value = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
}
