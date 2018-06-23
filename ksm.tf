resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${random_id.environment_name.hex}"
  target_key_id = "${aws_kms_key.vault.key_id}"
}

module "vault_instance_profile" {
  region           = "${var.region}"
  source           = "./instance-policy"
  environment_name = "${random_id.environment_name.hex}"
  kms_arn          = "${aws_kms_key.vault.arn}"
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${lookup(var.resource_tags, "ClusterName")}-"
}
