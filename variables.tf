//-------------------------------------------------------------------
// Vault settings
//-------------------------------------------------------------------

variable "download_url" {
  default     = "https://releases.hashicorp.com/vault/0.10.3/vault_0.10.3_linux_amd64.zip"
  description = "URL to download Vault"
}

variable "config" {
  description = "Configuration (text) for Vault"
}

variable "extra_install" {
  default     = ""
  description = "Extra commands to run in the install script"
}

//-------------------------------------------------------------------
// AWS settings
//-------------------------------------------------------------------

variable "availability_zone" {
  default     = "us-east-1a"
  description = "Availability zones for launching the Vault instances"
}

variable "elb_health_check" {
  default     = "HTTP:8200/v1/sys/health"
  description = "Health check for Vault servers"
}

variable "instance_type" {
  default     = "m3.medium"
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