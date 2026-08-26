resource "yandex_kms_symmetric_key" "k8s_encryption_key" {
  name              = "k8s-encryption-key"
  description       = "KMS key for encrypting Kubernetes cluster secrets"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  deletion_protection = true
}

output "kms_key_id" {
  value = yandex_kms_symmetric_key.k8s_encryption_key.id
}
