resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${random_id.environment_name.hex}"
  target_key_id = "${aws_kms_key.vault.key_id}"
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${lookup(var.resource_tags, "ClusterName")}-"
}
