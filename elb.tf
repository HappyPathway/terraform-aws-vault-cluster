resource "aws_elb" "vault" {
  name                        = "vault-${lookup(var.resource_tags, "ClusterName")}-${lookup(var.resource_tags, "Owner")}"
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
