##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  owner_users = merge(
    {
      for k, v in var.users : k => v
      if try(v.resource_group, try(v.grant, "owner") == "owner" ? "owner" : "user") == "owner"
    },
    var.owner_users,
  )
  users = {
    for k, v in var.users : k => v
    if try(v.resource_group, try(v.grant, "owner") == "owner" ? "owner" : "user") == "user"
  }

  # Authentication plugins that do not authenticate against a password the server stores.
  # They delegate the credential to the OS, Kerberos/AD, LDAP, PAM, a hardware token or a
  # cloud IAM service, or they disable login outright. A password held by this module would
  # never authenticate these accounts, and for some it is actively harmful: the provider
  # appends "BY '<password>'", which authentication_kerberos reads as its realm name.
  #
  # MySQL 8.4: https://dev.mysql.com/doc/refman/8.4/en/authentication-plugins.html
  # MariaDB:   https://mariadb.com/docs/server/reference/plugins/authentication-plugins
  passwordless_auth_plugins = [
    # MySQL 8.4
    "auth_socket",                # OS socket peer credentials
    "authentication_kerberos",    # takes BY '<realm_name>', not a password
    "authentication_ldap_sasl",   # takes AS '<ldap_dn>'
    "authentication_ldap_simple", # takes AS '<ldap_dn>'
    "authentication_pam",         # takes AS '<pam_service_name>'
    "authentication_webauthn",    # hardware authenticator
    "authentication_windows",     # Windows SSPI
    "mysql_no_login",             # login disabled outright
    # MariaDB
    "gssapi",      # Kerberos / SSPI single sign-on
    "named_pipe",  # Windows named-pipe peer credentials
    "pam",         # PAM
    "unix_socket", # OS socket peer credentials
    # Cloud-managed IAM
    "aad_auth",                # Azure Database for MySQL, Microsoft Entra ID
    "AWSAuthenticationPlugin", # Amazon RDS / Aurora IAM authentication
  ]

  # Plugin names are compared case-insensitively so mixed-case spellings such as
  # AWSAuthenticationPlugin match however the operator writes them. `try(lower(...), "")`
  # absorbs both an absent attribute and an explicit null, which is what a wrapper emits
  # when it maps the attribute through unconditionally.
  passwordless_auth_plugins_lower = [for p in local.passwordless_auth_plugins : lower(p)]

  # user_ref => true when this module must not hold a password for the account, either
  # because the plugin authenticates without one or because the operator supplied the hash.
  owner_password_suppressed = {
    for k, v in local.owner_users : k => (
      contains(local.passwordless_auth_plugins_lower, try(lower(v.auth_plugin), ""))
      || try(v.auth_string, v.auth_string_hashed, null) != null
    )
  }
  user_password_suppressed = {
    for k, v in local.users : k => (
      contains(local.passwordless_auth_plugins_lower, try(lower(v.auth_plugin), ""))
      || try(v.auth_string, v.auth_string_hashed, null) != null
    )
  }

  # user_ref => true when this module generates the password itself. Suppressed accounts
  # never generate one, so no random_password is created and no secret reaches the outputs.
  owner_generate_password = {
    for k, v in local.owner_users : k => (
      !local.owner_password_suppressed[k]
      && try(v.generate_password, try(v.password, null) == null)
    )
  }
  user_generate_password = {
    for k, v in local.users : k => (
      !local.user_password_suppressed[k]
      && try(v.generate_password, try(v.password, null) == null)
    )
  }
}

resource "mysql_database" "this" {
  for_each = {
    for k, v in var.databases : k => v if try(v.create, true)
  }
  name                  = try(each.value.name, each.key)
  default_character_set = try(each.value.default_character_set, each.value.charset, "utf8mb4")
  default_collation     = try(each.value.default_collation, each.value.collation, "utf8mb4_unicode_ci")
}

resource "time_rotating" "owner" {
  for_each = {
    for k, v in local.owner_users : k => v
    if local.owner_generate_password[k] && var.password_rotation_period > 0
  }
  rotation_days = var.password_rotation_period
}

resource "random_password" "owner" {
  for_each = {
    for k, v in local.owner_users : k => v if local.owner_generate_password[k]
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
    replace_triggered_by = [time_rotating.owner]
  }
}

resource "mysql_user" "owner" {
  for_each = local.owner_users
  user     = try(each.value.name, each.key)
  host     = try(each.value.host, "%")
  plaintext_password = local.owner_generate_password[each.key] ? random_password.owner[each.key].result : (
    local.owner_password_suppressed[each.key] ? null : try(each.value.password, null)
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

resource "mysql_grant" "owner" {
  for_each = {
    for item in flatten([
      for k, v in local.owner_users : [
        for db in try(v.databases, []) : {
          key      = "${k}-${db}"
          user_key = k
          username = try(v.name, k)
          host     = try(v.host, "%")
          database = db
        }
      ] if try(v.manage_grants, true)
    ]) : item.key => item
  }
  user       = each.value.username
  host       = each.value.host
  database   = each.value.database
  privileges = ["ALL"]
  depends_on = [mysql_user.owner, mysql_database.this]
}
