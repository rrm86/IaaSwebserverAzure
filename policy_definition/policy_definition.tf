provider "azurerm" {
  version = "~> 2.27.0"
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id 
}

resource "azurerm_policy_definition" "example" {
  name         = "taggind-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "tagging-policy"

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
            {
                "value": "[empty(field('tags'))]",
                "equals": "true"
            }
        ]
    },
    "then": {
        "effect": "deny"
    }
  }
POLICY_RULE
metadata = <<METADATA
    {
    "createdBy": "Ronnald R Machado"
    }
METADATA
}
resource "azurerm_policy_assignment" "example" {
  name                 = "taggind-policy"
  scope                = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.example.id
  description          = "Policy as code"
  display_name         = "taggind-policy"

  metadata = <<METADATA
    {
    "createdBy": "Ronnald R Machado"
    }
METADATA

}