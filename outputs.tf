output "summary" {
  value = <<-EOT
    ============================================
    Инфраструктура развёрнута успешно!
    ============================================
    
    VPC Network: ${yandex_vpc_network.main.name}
    
    MySQL Cluster:
      ID:   ${yandex_mdb_mysql_cluster.mysql_cluster.id}
      FQDN: ${yandex_mdb_mysql_cluster.mysql_cluster.host[0].fqdn}
      DB:   ${var.mysql_db_name}
      User: ${var.mysql_user_login}
    
    Kubernetes Cluster:
      ID:       ${yandex_kubernetes_cluster.k8s_cluster.id}
      Endpoint: ${yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint}
    
    KMS Key: ${yandex_kms_symmetric_key.k8s_encryption_key.id}
    ============================================
  EOT
}
