variable "region" {}

variable "kms_arn" {}

variable "resource_tags" {
  default     = {}
  type        = "map"
  description = "Optional map of config tags"
}
