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
#     tls_option: "NONE"         # (Optional) MySQL TLS requirement. Default: provider default.
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
#     host: "%"                 # (Optional) Host restriction. Default: "%".
#     tls_option: "NONE"        # (Optional) MySQL TLS requirement. Default: provider default.
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
