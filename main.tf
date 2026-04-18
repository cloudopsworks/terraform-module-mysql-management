##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "mysql_database" "this" {
  for_each              = var.databases
  name                  = try(each.value.name, each.key)
  default_character_set = try(each.value.charset, "utf8mb4")
  default_collation     = try(each.value.collation, "utf8mb4_unicode_ci")
}

resource "time_rotating" "owner" {
  for_each = {
    for k, v in var.users : k => v if try(v.grant, "owner") == "owner" && var.password_rotation_period > 0
  }
  rotation_days = var.password_rotation_period
}

resource "random_password" "owner" {
  for_each = {
    for k, v in var.users : k => v if try(v.grant, "owner") == "owner"
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
  for_each           = { for k, v in var.users : k => v if try(v.grant, "owner") == "owner" }
  user               = try(each.value.name, each.key)
  host               = try(each.value.host, "%")
  plaintext_password = random_password.owner[each.key].result
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
      ] if try(v.grant, "owner") == "owner"
    ]) : item.key => item
  }
  user       = each.value.username
  host       = each.value.host
  database   = each.value.database
  privileges = ["ALL"]
  depends_on = [mysql_user.owner, mysql_database.this]
}
