terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.27.0"
    }
  }
}

provider "azurerm" {
  version = "~> 2.27.0"
  features {}
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "application_resource_group" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.application_resource_group.name
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  tags = var.tags
  depends_on = [azurerm_resource_group.application_resource_group]
}

module "network-security-group" {
  source              = "Azure/network-security-group/azurerm//modules/HTTP"
  resource_group_name = azurerm_resource_group.application_resource_group.name
  security_group_name = "${var.prefix}-security-group"
  source_address_prefix = ["10.0.1.0/24"]
  custom_rules = [
    {
      name                   = "AllowVNetInBound"
      priority               = "200"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "VirtualNetwork"
      description            = "AllowVNetInBound"
    },
    {
      name                   = "AllowVnetOutBound"
      priority               = "250"
      direction              = "Outbound"
      access                 = "Allow"
      protocol               = "*"
      destination_port_range = "*"
      source_address_prefix  = "VirtualNetwork"
      description            = "all"
    }
  ]
  tags = var.tags
  depends_on = [azurerm_resource_group.application_resource_group]
}

resource "azurerm_network_interface" "application_network_interface" {
  count               = var.instance_count
  name                = "${var.prefix}-ni-${count.index}"
  resource_group_name = azurerm_resource_group.application_resource_group.name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    
    name     = "application_network_interface_configuration-${count.index}"
    subnet_id = module.vnet.vnet_subnets[0]#use only one subnet
    private_ip_address_allocation = "Dynamic"
  }

}
resource "azurerm_public_ip" "application_public_ip" {
  count               = var.instance_count
  name                = "application_public_ip-${count.index}"
  resource_group_name = azurerm_resource_group.application_resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "application_load_balancer" {
  count               = var.instance_count
  name                = "${var.prefix}-loadbalancer"
  resource_group_name = azurerm_resource_group.application_resource_group.name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags
  frontend_ip_configuration {
    name                 = "PublicIPAddress-${count.index}"
    public_ip_address_id = azurerm_public_ip.application_public_ip[count.index].id
  }
}

resource "azurerm_lb_backend_address_pool" "application_load_balancer_backend_address_pool" {
  count               = var.instance_count
  resource_group_name = azurerm_resource_group.application_resource_group.name
  loadbalancer_id     = azurerm_lb.application_load_balancer[count.index].id
  name                = "BackEndAddressPool-${count.index}"
}

resource "azurerm_network_interface_backend_address_pool_association" "application_load_balancer_backend_address_pool_association" {
  count                   = var.instance_count
  network_interface_id    = azurerm_network_interface.application_network_interface[count.index].id
  ip_configuration_name   = "application_network_interface_configuration-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.application_load_balancer_backend_address_pool[count.index].id
}

resource "azurerm_availability_set" "application_availability_set" {
  name                = "application_availability_set"
  location            = var.location
  resource_group_name = azurerm_resource_group.application_resource_group.name

  tags = var.tags
}

data "azurerm_resource_group" "packer_rg" {
  name = var.image_resource_group
}

data "azurerm_image" "packer_image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.packer_rg.name
}

resource "azurerm_linux_virtual_machine" "application_linux_virtual_machine" {
  count               = var.instance_count
  name                = "${var.prefix}-machines-${count.index}"
  resource_group_name = azurerm_resource_group.application_resource_group.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = var.virtual_machine_user
  admin_password      = var.virtual_machine_password
  disable_password_authentication = false
  tags = var.tags
  source_image_id     = data.azurerm_image.packer_image.id

  availability_set_id = azurerm_availability_set.application_availability_set.id

  network_interface_ids = [
    azurerm_network_interface.application_network_interface[count.index].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_managed_disk" "application_managed_disk" {
  count                = var.instance_count
  name                 = "application_managed_disk_${count.index}"
  resource_group_name  = azurerm_resource_group.application_resource_group.name
  location             = var.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "application_virtual_machine_data_disk_attachment" {
  count              = var.instance_count
  managed_disk_id    = azurerm_managed_disk.application_managed_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.application_linux_virtual_machine[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}