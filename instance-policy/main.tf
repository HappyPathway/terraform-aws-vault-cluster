provider "aws" {
  region = "${var.region}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault" {
  statement {
    sid       = "AllowSelfAssembly"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeTags",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
  }

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      "${var.kms_arn}",
    ]
  }
}

resource "aws_iam_role" "vault" {
  name               = "vault-${lookup(var.resource_tags, "ClusterName")}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "vault" {
  name   = "vault-${lookup(var.resource_tags, "ClusterName")}"
  role   = "${aws_iam_role.hashistack.id}"
  policy = "${data.aws_iam_policy_document.hashistack.json}"
}

resource "aws_iam_instance_profile" "vault" {
  name = "vault-${lookup(var.resource_tags, "ClusterName")}"
  role = "${aws_iam_role.hashistack.name}"
}
