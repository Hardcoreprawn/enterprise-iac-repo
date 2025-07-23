output "devops_service_principals" {
  description = "Service principals created for DevOps automation"
  value = {
    for key, sp in azuread_service_principal.devops_sps : key => {
      object_id      = sp.object_id
      client_id      = sp.client_id
      display_name   = sp.display_name
      client_secret  = azuread_service_principal_password.devops_sp_passwords[key].value
    }
  }
  sensitive = true
}

output "service_principal_object_ids" {
  description = "Map of service principal object IDs for role assignments"
  value = {
    for key, sp in azuread_service_principal.devops_sps : key => sp.object_id
  }
}

output "security_groups" {
  description = "Security groups created for team organization"
  value = {
    for key, group in azuread_group.security_groups : key => {
      object_id    = group.object_id
      display_name = group.display_name
      description  = group.description
    }
  }
}

output "application_registrations" {
  description = "Application registration details for DevOps tools"
  value = {
    for key, app in azuread_application.devops_apps : key => {
      application_id = app.application_id
      client_id      = app.client_id
      object_id      = app.object_id
      display_name   = app.display_name
    }
  }
}
