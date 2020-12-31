variable "virtual_machine_user" {
  description = "Your VM user"
  type        = string
}

variable "virtual_machine_password" {
  description = "Your VM password"
  type        = string
}

variable "location" {
  description = "Azure Region"
  default     = "brazilsouth"
}

variable "resource_group_name" {
  description = "Resource Group Name"
  default     = "application-rg"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be assigned to resources when created"

  default = {
    project = "Load Balancer Application"
  }
}

variable "prefix" {
  description = "The prefix used for all resources in this example"
  default     = "terraform-deploy"
}

variable "instance_count" {
  description = "Number machines to be created"
  type        = number
  default     = 2
}

variable "image_resource_group" {
  description = "Image resource group"
  default     = "packer-rg"
}

variable "packer_image_name" {
  description = "Name of image to be used on Virtual Machines"
  default     = "myPackerImage3"
}

variable "tenant_id" {
  type        = string
  description = "Used for logging in"
}