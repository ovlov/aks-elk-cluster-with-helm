resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-aks-elk-rg"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-appgw-network"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.254.2.0/24"]
}

resource "azurerm_subnet" "aks_node" {
  name                 = "aks-node"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.254.4.0/24"]
    delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "aks_pod" {
  name                 = "aks-pods"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.254.6.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name_prefix}-appgw-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.this.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.this.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.this.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.this.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.this.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.this.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.this.name}-rdrcfg"
}

resource "azurerm_application_gateway" "app_gw" {
  name                = "${var.name_prefix}-appgateway"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.name_prefix}-elk-aks1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "${var.name_prefix}elkaks1"
  oidc_issuer_enabled = true
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = var.vm_size
    pod_subnet_id  = azurerm_subnet.aks_node.id
    vnet_subnet_id = azurerm_subnet.aks_pod.id
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.app_gw.id
  }

  tags = {
    Environment = "aks-${var.name_prefix}-elk-Setup"
  }
}

resource "azurerm_role_assignment" "aks_appgw_identity_assignment" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [
    azurerm_kubernetes_cluster.this,
    azurerm_application_gateway.app_gw
  ]
}

resource "azurerm_role_assignment" "aks_identity_assignment" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id

  depends_on = [
    azurerm_kubernetes_cluster.this,
    azurerm_application_gateway.app_gw
  ]
}