# ==========================================
# ЕДИНАЯ VPC для MySQL и Kubernetes
# ==========================================
resource "yandex_vpc_network" "main" {
  name = "clusters-network"
}

# ==========================================
# Private подсети для MySQL (3 зоны)
# ==========================================
resource "yandex_vpc_subnet" "mysql_a" {
  name           = "mysql-private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_subnet" "mysql_b" {
  name           = "mysql-private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "mysql_d" {
  name           = "mysql-private-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

# ==========================================
# Public подсети для Kubernetes (3 зоны)
# ==========================================
resource "yandex_vpc_subnet" "k8s_a" {
  name           = "k8s-public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.0.0/24"]
}

resource "yandex_vpc_subnet" "k8s_b" {
  name           = "k8s-public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.1.0/24"]
}

resource "yandex_vpc_subnet" "k8s_d" {
  name           = "k8s-public-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.2.0/24"]
}

# ==========================================
# Security Group для MySQL
# ==========================================
resource "yandex_vpc_security_group" "mysql_sg" {
  name        = "mysql-security-group"
  description = "Security group for MySQL cluster"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow MySQL from K8s subnets"
    v4_cidr_blocks = [
      yandex_vpc_subnet.k8s_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.k8s_b.v4_cidr_blocks[0],
      yandex_vpc_subnet.k8s_d.v4_cidr_blocks[0]
    ]
    port = 3306
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# Security Group для Kubernetes
# ==========================================
resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTPS from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow NodePort range"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  # НОВОЕ ПРАВИЛО: Порт kubelet для port-forward, exec, logs
  ingress {
    protocol       = "TCP"
    description    = "Allow kubelet API from master for port-forward/exec"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 10250
    to_port        = 10250
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_network_id" {
  value = yandex_vpc_network.main.id
}
