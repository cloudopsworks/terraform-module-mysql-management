##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "time_rotating" "user" {
  for_each = {
    for k, v in local.users : k => v
    if local.user_generate_password[k] && var.password_rotation_period > 0
  }
  rotation_days = var.password_rotation_period
}

resource "random_password" "user" {
  for_each = {
    for k, v in local.users : k => v if local.user_generate_password[k]
  }
  length           = 25
  special          = var.specials_in_password
  override_special = "=_-+@~#"
  min_upper        = 2
  min_special      = var.specials_in_password ? 2 : 0
  min_numeric      = 2
  min_lower        = 2
  # `keepers` is written only when a reset is actually requested. Leaving the attribute
  # absent by default lets a wrapper hand its own keepers-less `random_password` over with
  # a `moved` block: Terraform sees no keepers change, so the password is adopted in place
  # instead of being replaced.
  keepers = var.force_reset ? { force_reset = "true" } : null
  lifecycle {
    replace_triggered_by = [time_rotating.user]
  }
}

resource "mysql_user" "user" {
  for_each = local.users
  user     = try(each.value.name, each.key)
  host     = try(each.value.host, "%")
  plaintext_password = local.user_generate_password[each.key] ? random_password.user[each.key].result : (
    local.user_password_suppressed[each.key] ? null : try(each.value.password, null)
  )
  tls_option           = try(each.value.tls_option, null)
  max_user_connections = try(each.value.max_user_connections, null)
  max_statement_time   = try(each.value.max_statement_time, null)
  auth_plugin          = try(each.value.auth_plugin, null)
  auth_string_hashed   = try(each.value.auth_string, each.value.auth_string_hashed, null)
  dynamic "aad_identity" {
    for_each = try(each.value.auth_plugin, null) == "aad_auth" ? [1] : []
    content {
      type     = try(each.value.aad_identity.type, null)
      identity = try(each.value.aad_identity.identity, null)
    }
  }
}

resource "mysql_grant" "readwrite" {
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
      ] if try(v.grant, "owner") == "readwrite" && try(v.manage_grants, true)
    ]) : item.key => item
  }
  user       = each.value.username
  host       = each.value.host
  database   = each.value.database
  privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "INDEX", "ALTER"]
  depends_on = [mysql_user.user, mysql_database.this]
}

resource "mysql_grant" "readonly" {
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
      ] if try(v.grant, "owner") == "readonly" && try(v.manage_grants, true)
    ]) : item.key => item
  }
  user       = each.value.username
  host       = each.value.host
  database   = each.value.database
  privileges = ["SELECT"]
  depends_on = [mysql_user.user, mysql_database.this]
}
