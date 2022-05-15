provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "subnet" {
  name                = "${var.prefix}-subnet-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_sub" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.subnet.id
}

resource "azurerm_network_interface" "vm" {
  count               = 2
  name                = "${var.prefix}-vm${count.index}-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "vmSet" {
  name                         = "${var.prefix}-vm-set"
  location                     = data.azurerm_resource_group.main.location
  resource_group_name          = data.azurerm_resource_group.main.name
  platform_update_domain_count = var.server_count
  platform_fault_domain_count  = var.server_count
}

data "azurerm_image" "main" {
  name                = "packer-image"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.server_count
  name                            = "${var.prefix}-vm${count.index}"
  location                        = data.azurerm_resource_group.main.location
  resource_group_name             = data.azurerm_resource_group.main.name
  availability_set_id             = azurerm_availability_set.vmSet.id
  size                            = "Standard_B1s"
  source_image_id                 = data.azurerm_image.main.id
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    element(azurerm_network_interface.vm.*.id, count.index)
  ]

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  user_data = filebase64("user_data.txt")
}

resource "azurerm_managed_disk" "vmDisk" {
  count                = var.server_count
  name                 = "${var.prefix}-vm${count.index}-disk"
  location             = data.azurerm_resource_group.main.location
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "5"
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_vm" {
  count = var.server_count
  managed_disk_id    = azurerm_managed_disk.vmDisk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_public_ip" "lb" {
  name                = "${var.prefix}-lb-ip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-lb-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.server_count
  network_interface_id    = azurerm_network_interface.vm[count.index].id
  ip_configuration_name   = azurerm_network_interface.vm[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_probe" "main" {
  name            = "${var.prefix}-lb-probe"
  loadbalancer_id = azurerm_lb.main.id
  port            = var.application_port
}

resource "azurerm_lb_rule" "main" {
  name                           = "${var.prefix}-lb-rule-http"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.main.id
}
