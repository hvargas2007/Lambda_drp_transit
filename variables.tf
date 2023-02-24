### Global variables:
variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "project-tags" {
  type = map(string)
  default = {
  }
}

# variable "route_table_id" {
#   description = "[REQUERIDO] es REQUERIDO para nombres de recursos"
#   type        = list(string)
#   default = [
#   ]
# }

variable "attach_vpn" {
  description = "[REQUIRED] The Public Subnet ID to place the EC2 instance"
  type        = string
}

variable "attach_dxc" {
  description = "[REQUERIDO] Subnet ID"
  type        = string
}

variable "cidr_block" {
  description = "[REQUERIDO] Subnet ID"
  type        = string
}


