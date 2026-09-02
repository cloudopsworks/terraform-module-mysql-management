##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

## databases: map of MySQL databases
# databases:
#   <db_ref>:
#     name: "dbname"                     # (Required) Database name.
#     create: true                        # (Optional) Whether to manage the database. Default: true.
#     charset: "utf8mb4"                 # (Optional) Character set. Default: "utf8mb4".
#     collation: "utf8mb4_unicode_ci"    # (Optional) Collation. Default: "utf8mb4_unicode_ci".
variable "databases" {
  description = "Map of MySQL databases to create. See inline docs for full schema."
  type        = any
  default     = {}
}

## users: map of MySQL users
# users:
#   <user_ref>:
#     name: "username"          # (Required) MySQL user name.
#     host: "%"                 # (Optional) Host restriction. Default: "%".
#     grant: "owner"            # (Required) Grant type: owner | readwrite | readonly.
#     databases: ["mydb"]       # (Required) List of database names to grant access on.
#     password: "external"       # (Optional, sensitive) Externally managed password. Default: generated.
#     generate_password: false    # (Optional) Generate a password here. Default: true when password is omitted. Forced off when auth_plugin delegates authentication (auth_socket, authentication_kerberos/ldap_*/pam/webauthn/windows, mysql_no_login, gssapi, named_pipe, pam, unix_socket, aad_auth, AWSAuthenticationPlugin) or when auth_string is set.
#     tls_option: "NONE"         # (Optional) MySQL TLS requirement. Default: provider default.
#     auth_plugin: "caching_sha2_password" # (Optional) Authentication plugin. One of: mysql_native_password | caching_sha2_password | sha256_password | aad_auth. Default: server default.
#     auth_string: "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19" # (Optional, sensitive) Already-hashed authentication string for auth_plugin. Alias of auth_string_hashed. Default: null.
#     auth_string_hashed: "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19" # (Optional, sensitive) Already-hashed authentication string; used only when auth_string is absent. Default: null.
#     aad_identity:                        # (Optional) Azure AD identity block. Only rendered when auth_plugin is "aad_auth"; ignored otherwise.
#       type: "user"                       # (Optional) Identity type: user | group | service_principal. Default: provider default.
#       identity: "app@contoso.com"        # (Required when auth_plugin is "aad_auth") Azure AD user/group name or service principal object ID.
#     max_user_connections: 0     # (Optional) Simultaneous connection limit, 0 = unlimited. Default: server default.
#     max_statement_time: 0       # (Optional) Statement execution limit in seconds, 0 = unlimited. MariaDB 10.1.1+ only. Default: server default.
#     resource_group: "owner"    # (Optional) Stable resource group: owner | user. Default: derived from grant.
#     manage_grants: true         # (Optional) Whether this module manages grants. Default: true.
variable "users" {
  description = "Map of MySQL users. See inline docs for full schema."
  type        = any
  default     = {}
}

## owner_users: optional map for wrappers that preserve owner and regular-user key spaces
# owner_users:
#   <owner_ref>:
#     name: "database_owner"    # (Required) MySQL owner user name.
#     password: "external"      # (Optional, sensitive) Externally managed password. Default: generated.
#     generate_password: false   # (Optional) Generate a password here. Default: true when password is omitted. Forced off when auth_plugin delegates authentication (auth_socket, authentication_kerberos/ldap_*/pam/webauthn/windows, mysql_no_login, gssapi, named_pipe, pam, unix_socket, aad_auth, AWSAuthenticationPlugin) or when auth_string is set.
#     host: "%"                 # (Optional) Host restriction. Default: "%".
#     tls_option: "NONE"        # (Optional) MySQL TLS requirement. Default: provider default.
#     auth_plugin: "caching_sha2_password" # (Optional) Authentication plugin. One of: mysql_native_password | caching_sha2_password | sha256_password | aad_auth. Default: server default.
#     auth_string: "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19" # (Optional, sensitive) Already-hashed authentication string for auth_plugin. Alias of auth_string_hashed. Default: null.
#     auth_string_hashed: "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19" # (Optional, sensitive) Already-hashed authentication string; used only when auth_string is absent. Default: null.
#     aad_identity:                        # (Optional) Azure AD identity block. Only rendered when auth_plugin is "aad_auth"; ignored otherwise.
#       type: "user"                       # (Optional) Identity type: user | group | service_principal. Default: provider default.
#       identity: "app@contoso.com"        # (Required when auth_plugin is "aad_auth") Azure AD user/group name or service principal object ID.
#     max_user_connections: 0   # (Optional) Simultaneous connection limit, 0 = unlimited. Default: server default.
#     max_statement_time: 0     # (Optional) Statement execution limit in seconds, 0 = unlimited. MariaDB 10.1.1+ only. Default: server default.
#     databases: ["mydb"]       # (Optional) Databases to grant when manage_grants is true. Default: [].
#     manage_grants: true        # (Optional) Whether this module manages grants. Default: true.
variable "owner_users" {
  description = "Optional owner-user map with an independent key space for state-compatible wrapper migrations."
  type        = any
  default     = {}
}

## password_rotation_period: days between rotations (0 = no time-based rotation)
variable "password_rotation_period" {
  description = "(Optional) Password rotation period in days. Default: 0."
  type        = number
  default     = 0
}

## force_reset: force password replacement on next apply
variable "force_reset" {
  description = "(Optional) Force password reset on next apply. Default: false."
  type        = bool
  default     = false
}

## specials_in_password: use special characters in generated passwords
variable "specials_in_password" {
  description = "(Optional) Use special characters (=_-+@~#) in generated owner/user passwords. When false, generated passwords are alphanumeric only. Default: true."
  type        = bool
  default     = true
  nullable    = false
}
