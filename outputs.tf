##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "owner_passwords" {
  description = "Map of user_ref → owner password (sensitive). Consumed by cloud modules for secret storage. Accounts whose auth_plugin authenticates without a password, or that supply auth_string, are omitted."
  sensitive   = true
  value = {
    for k, v in local.owner_users : k => (
      local.owner_generate_password[k] ? random_password.owner[k].result : try(v.password, null)
    ) if !local.owner_password_suppressed[k]
  }
}

output "owner_usernames" {
  description = "Map of user_ref → MySQL username for owner-grant users."
  value       = { for k, v in mysql_user.owner : k => v.user }
}

output "user_passwords" {
  description = "Map of user_ref → user password (sensitive). Consumed by cloud modules for secret storage. Accounts whose auth_plugin authenticates without a password, or that supply auth_string, are omitted."
  sensitive   = true
  value = {
    for k, v in local.users : k => (
      local.user_generate_password[k] ? random_password.user[k].result : try(v.password, null)
    ) if !local.user_password_suppressed[k]
  }
}

output "user_usernames" {
  description = "Map of user_ref → MySQL username for non-owner users."
  value       = { for k, v in mysql_user.user : k => v.user }
}

output "databases" {
  description = "Map of db_ref → { name } for all managed databases."
  value       = { for k, v in mysql_database.this : k => { name = v.name } }
}

output "users" {
  description = "Map of user_ref → { name, grant } for all managed users."
  value = {
    for k, v in var.users : k => {
      name  = try(v.name, k)
      grant = try(v.grant, "owner")
    }
  }
}

output "owner_password_managed" {
  description = "Map of user_ref → whether this module holds a password for the owner account. False when auth_plugin authenticates without a password or auth_string is supplied, in which case the user_ref is absent from owner_passwords. Plan-time known, so consumers may use it in for_each."
  value       = { for k, v in local.owner_users : k => !local.owner_password_suppressed[k] }
}

output "user_password_managed" {
  description = "Map of user_ref → whether this module holds a password for the user account. False when auth_plugin authenticates without a password or auth_string is supplied, in which case the user_ref is absent from user_passwords. Plan-time known, so consumers may use it in for_each."
  value       = { for k, v in local.users : k => !local.user_password_suppressed[k] }
}

output "passwordless_auth_plugins" {
  description = "Lower-cased list of auth_plugin values this module treats as authenticating without a stored password. Derived from a static list, so unlike owner_password_managed / user_password_managed it carries no dependency on the module's inputs and can safely drive a consumer's for_each."
  value       = local.passwordless_auth_plugins_lower
}
