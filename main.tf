resource "template_file" "install" {
  template = "${file("${path.module}/scripts/install.sh.tpl")}"

  vars {
    vault_download_url  = "${var.vault_download_url}"
    consul_download_url = "${var.consul_download_url}"
    consul_cluster      = "${var.consul_cluster}"
    config              = "${var.config}"
    extra-install       = "${var.extra_install}"
    region              = "${var.region}"
    kms_id              = "${aws_kms_key.vault.key_id}"
    hash                = "${random_id.environment_name.hex}"
  }
}

data "aws_ami" "hashistack" {
  most_recent = true
  owners      = ["753646501470"]

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:service_name"
    values = ["${var.service_name}"]
  }

  filter {
    name   = "tag:service_version"
    values = ["${var.service_version}"]
  }
}

// We launch Vault into an ASG so that it can properly bring them up for us.
resource "aws_autoscaling_group" "vault" {
  name                      = "vault - ${aws_launch_configuration.vault.name}"
  launch_configuration      = "${aws_launch_configuration.vault.name}"
  availability_zones        = ["${var.availability_zone}"]
  min_size                  = "${var.servers}"
  max_size                  = "${var.servers}"
  desired_capacity          = "${var.servers}"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${var.subnet}"]
  load_balancers            = ["${aws_elb.vault.id}"]

  tag {
    key                 = "Name"
    value               = "${lookup(var.resource_tags, "ClusterName")}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = "${lookup(var.resource_tags, "Owner")}"
    propagate_at_launch = true
  }

  tag {
    key                 = "TTL"
    value               = "${lookup(var.resource_tags, "TTL")}"
    propagate_at_launch = true
  }
}

module "vault_instance_profile" {
  region           = "${var.region}"
  source           = "./instance-policy"
  environment_name = "${random_id.environment_name.hex}"
  kms_arn          = "${aws_kms_key.vault.arn}"
  resource_tags    = "${var.resource_tags}"
}

resource "aws_launch_configuration" "vault" {
  image_id             = "${data.aws_ami.hashistack.id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.vault.id}"]
  user_data            = "${template_file.install.rendered}"
  iam_instance_profile = "${module.vault_instance_profile.policy}"
}

// Security group for Vault allows SSH and HTTP access (via "tcp" in
// case TLS is used)
resource "aws_security_group" "vault" {
  name        = "vault"
  description = "Vault servers"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vault-ssh" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

// This rule allows Vault HTTP API access to individual nodes, since each will
// need to be addressed individually for unsealing.
resource "aws_security_group_rule" "vault-http-api" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-egress" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

// Launch the ELB that is serving Vault. This has proper health checks
// to only serve healthy, unsealed Vaults.
resource "aws_elb" "vault" {
  name                        = "vault"
  connection_draining         = true
  connection_draining_timeout = 400
  internal                    = true
  subnets                     = ["${var.subnet}"]
  security_groups             = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 8200
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8200
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    target              = "${var.elb_health_check}"
    interval            = 15
  }
}

resource "aws_security_group" "elb" {
  name        = "vault-elb"
  description = "Vault ELB"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vault-elb-http" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-elb-https" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-elb-egress" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
