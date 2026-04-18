##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "owner_passwords" {
  description = "Map of user_ref → owner password (sensitive). Consumed by cloud modules for secret storage."
  sensitive   = true
  value       = { for k, v in random_password.owner : k => v.result }
}

output "owner_usernames" {
  description = "Map of user_ref → MySQL username for owner-grant users."
  value       = { for k, v in mysql_user.owner : k => v.user }
}

output "user_passwords" {
  description = "Map of user_ref → user password (sensitive). Consumed by cloud modules for secret storage."
  sensitive   = true
  value       = { for k, v in random_password.user : k => v.result }
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
