##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "mysql_database" "this" {
  for_each = {
    for k, v in var.databases : k => v if try(v.create, true)
  }
  name                  = try(each.value.name, each.key)
  default_character_set = try(each.value.default_character_set, each.value.charset, "utf8mb4")
  default_collation     = try(each.value.default_collation, each.value.collation, "utf8mb4_unicode_ci")
}

import {
  for_each = {
    for k, v in var.databases : k => v if try(v.create, true) && try(v.import, false)
  }
  to = mysql_database.this[each.key]
  id = try(each.value.name, each.key)
}

resource "time_rotating" "owner" {
  for_each = {
    for k, v in var.users : k => v
    if try(v.resource_group, try(v.grant, "owner") == "owner" ? "owner" : "user") == "owner" &&
    try(v.password, null) == null && var.password_rotation_period > 0
  }
  rotation_days = var.password_rotation_period
}

resource "random_password" "owner" {
  for_each = {
    for k, v in var.users : k => v
    if try(v.resource_group, try(v.grant, "owner") == "owner" ? "owner" : "user") == "owner" &&
    try(v.password, null) == null
  }
  length           = 25
  special          = true
  override_special = "=_-+@~#"
  min_upper        = 2
  min_special      = 2
  min_numeric      = 2
  min_lower        = 2
  keepers = {
    force_reset = var.force_reset
  }
  lifecycle {
    replace_triggered_by = [time_rotating.owner]
  }
}

resource "mysql_user" "owner" {
  for_each = {
    for k, v in var.users : k => v
    if try(v.resource_group, try(v.grant, "owner") == "owner" ? "owner" : "user") == "owner"
  }
  user               = try(each.value.name, each.key)
  host               = try(each.value.host, "%")
  plaintext_password = try(each.value.password, null) != null ? each.value.password : random_password.owner[each.key].result
  tls_option         = try(each.value.tls_option, null)
}

import {
  for_each = {
    for k, v in var.users : k => v
    if try(v.resource_group, try(v.grant, "owner") == "owner" ? "owner" : "user") == "owner" &&
    try(v.import, false)
  }
  to = mysql_user.owner[each.key]
  id = try(each.value.name, each.key)
}

resource "mysql_grant" "owner" {
  for_each = {
    for item in flatten([
      for k, v in var.users : [
        for db in try(v.databases, []) : {
          key      = "${k}-${db}"
          user_key = k
          username = try(v.name, k)
          host     = try(v.host, "%")
          database = db
        }
      ] if try(v.grant, "owner") == "owner" && try(v.manage_grants, true)
    ]) : item.key => item
  }
  user       = each.value.username
  host       = each.value.host
  database   = each.value.database
  privileges = ["ALL"]
  depends_on = [mysql_user.owner, mysql_database.this]
}
