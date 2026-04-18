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
variable "users" {
  description = "Map of MySQL users. See inline docs for full schema."
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
