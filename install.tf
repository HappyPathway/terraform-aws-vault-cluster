resource "template_file" "install" {
  template = "${file("${path.module}/scripts/install.sh.tpl")}"

  vars {
    consul_cluster = "${var.consul_cluster}"
    consul_token   = "${var.consul_token}"
    region         = "${var.region}"
    kms_id         = "${aws_kms_key.vault.key_id}"
    hash           = "${random_id.environment_name.hex}"
    datacenter     = "${var.consul_datacenter}"
    env            = "${var.env}"
    vault_license  = "${var.vault_license}"
  }
}
