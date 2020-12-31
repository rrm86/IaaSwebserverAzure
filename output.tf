output "instance_ip_addr" {
  value = module.vnet.vnet_subnets[0]
  description = "The subnet address."
}