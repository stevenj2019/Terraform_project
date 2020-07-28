provider "azurerm"{
    features {}
}

variable "location" { default = "eu-west-2"}
variable "tag" { default = "non-prod"}

resource "azurerm_resource_group" "rss_grp" {
    name        = ${format(lower("${var.location} - ${var.tag}"))}
    location    = var.location
    tags        = {
        environment = var.tag
    }
}
resource "azurerm_virtual_network" "vnet" {
    name                = ${format(lower("${var.location} - ${var.tag} - network"))}
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rss_grp.name
    tags                = {
        environment = var.tag
    }
}
resource "azurerm_subnet" "subnet" {
    name                    = ${format(lower("${var.location} - ${var.tag} - subnet1"))}
    resource_group_name     = azurerm_resource_group.rss_grp.name
    virtual_network_name    = azurerm_virtual_network.vnet.name
    address_prefixes        = ["10.0.2.0/24"]   
}
resource "azurerm_public_ip" "ip_addr" {
    name                = ${format(lower("${var.location} - ${var.tag} - ipaddress"))}
    location            = var.location
    resource_group_name = azurerm_resource_group.rss_grp.name
    allocation_method   = "Dynamic"
    tags                = {
        environment = var.tag 
    }
}
resource "azurerm_network_security_group" "NSG"{
    name                = ${format(lower("${var.location} - ${var.tag}-allow-ssh"))}
    location            = var.location
    resource_group_name = azurerm_resource_group.rss_grp.name
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"  
    }
    tags                = {
        environment = var.tag
    }
}
resource "azurerm_network_interface" "NIC" {
    name                = ${format(lower("${var.location} - ${var.tag} - NIC1"))}
    location            = var.location
    resource_group_name = azurerm_resource_group.rss_grp.name

    ip_configuration {
        name                            = ${format(lower("${var.location} - ${var.tag} - NIC1 - configuration"))}
        subnet_id                       = azurerm_subnet.subnet.id
        private_ip_address_allocation   = "Dynamic"
        publid_ip_address_id            = azurerm_public_ip.ip_addr.id
    }
    tags                = {
        environment = var.tag
    }
}
resource "azurerm_network_interface_security_group_association" "assosciate" {
    network_interface_id        = azurerm_network_interface.NIC.id
    network_security_group_id   = azurerm_network_security_group.NSG.id
}
resource "azurerm_storage_account" "storage" {
    name                        = ${format(lower("${var.location} - ${var.tag}-storageacc-1"))}
    resource_group_name         = azurerm_resource_group.name
    location                    = var.location
    account_replication_type    = "LRS"
    account_tier                = "standard"
    tags                        = {
        environment = var.tag
    }
}
resource "azurerm_linux_virtual_machine_scale_set" "VM Cluster" {
    name                    = ${format(lower("${var.location} - ${var.tag}-scaleset"))}
    resource_group_name     = azurerm_resource_group.name
    location                = var.location
    sku                     = ""
    admin_username          = "admin"
    computer_name_prefix    = ${format(lower("${var.location} - ${var.tag}-"))}

    capacity {
        default = 1
        minimum = 0
        maximum = 3
    }
    
    admin_ssh_key {
        username    = "admin"
        public_key  = file("~/.ssh/id_rsa.pub") 
    }

    source_image_reference {
        publisher   = "Canonical"
        offer       = "UbuntuServer"
        sku         = "18.04-LTS"
        version     = "latest" 
    }

    os_disk {
        storage_account_type    = "Standard_LRS"
        caching                 = "ReadWrite"
    }

    network_interface {
        ip_configuration {

        }
    }

}
output {

}