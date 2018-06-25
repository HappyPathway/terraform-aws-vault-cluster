variable "availability_zone" {
  default     = "us-east-1a"
  description = "Availability zones for launching the Vault instances"
}

variable "elb_health_check" {
  default     = "HTTP:8200/v1/sys/health"
  description = "Health check for Vault servers"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Instance type for Vault instances"
}

variable "key_name" {
  default     = "default"
  description = "SSH key name for Vault instances"
}

variable "servers" {
  default     = "3"
  description = "number of Vault instances"
}

variable "subnet" {
  description = "list of subnets to launch Vault within"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "resource_tags" {
  type        = "map"
  default     = {}
  description = "Resource Tags. Get applied anywhere tags can be applied"
}

variable "consul_cluster" {
  type        = "string"
  description = "IP Address of cluster bootstrap host"
}

variable "consul_token" {
  default     = ""
  description = "ACL Token for Consul Cluster"
}

variable "consul_datacenter" {
  default     = "dc1"
  description = "Consul DataCenter"
}

variable "region" {
  type        = "string"
  description = "AWS Region"
}

variable "service_name" {
  default = "vault"
}

variable "service_version" {
  default = "1.2.0"
}

variable "env" {}

variable "consul_cluster_sg" {}

variable "vault_license" {}
