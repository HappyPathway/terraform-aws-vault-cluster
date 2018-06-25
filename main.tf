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
    value               = "${lookup(var.resource_tags, "ClusterName")}-${var.env}"
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

  tag {
    key                 = "Role"
    value               = "vault"
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}

module "vault_instance_profile" {
  region        = "${var.region}"
  source        = "./instance-policy"
  kms_arn       = "${aws_kms_key.vault.arn}"
  resource_tags = "${var.resource_tags}"
}

resource "aws_launch_configuration" "vault" {
  image_id             = "${data.aws_ami.hashistack.id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.vault.id}"]
  user_data            = "${template_file.install.rendered}"
  iam_instance_profile = "${module.vault_instance_profile.policy}"
}
