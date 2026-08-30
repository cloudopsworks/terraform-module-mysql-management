##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

mock_provider "mysql" {}

variables {
  org = {
    organization_name = "cloudopsworks"
    organization_unit = "platform"
    environment_type  = "testing"
    environment_name  = "test"
  }

  databases = {
    app = {
      name      = "appdb"
      charset   = "utf8mb4"
      collation = "utf8mb4_unicode_ci"
    }
  }

  users = {
    app_owner = {
      name      = "app_owner"
      grant     = "owner"
      databases = ["appdb"]
    }
    app_writer = {
      name      = "app_writer"
      grant     = "readwrite"
      databases = ["appdb"]
    }
    app_reader = {
      name      = "app_reader"
      grant     = "readonly"
      databases = ["appdb"]
    }
  }

  password_rotation_period = 90
}

run "baseline_resource_contract" {
  command = plan

  assert {
    condition     = length(mysql_database.this) == 1
    error_message = "The module must create one database for the baseline input."
  }

  assert {
    condition     = length(mysql_user.owner) == 1
    error_message = "Owner users must remain in mysql_user.owner."
  }

  assert {
    condition     = length(mysql_user.user) == 2
    error_message = "Non-owner users must remain in mysql_user.user."
  }

  assert {
    condition     = length(mysql_grant.owner) == 1 && length(mysql_grant.readwrite) == 1 && length(mysql_grant.readonly) == 1
    error_message = "The baseline grant resources must remain stable."
  }
}

run "wrapper_compatibility_contract" {
  command = plan

  variables {
    databases = {
      managed = {
        name                  = "manageddb"
        create                = true
        default_character_set = "utf8mb4"
        default_collation     = "utf8mb4_general_ci"
      }
      external = {
        name   = "externaldb"
        create = false
      }
    }

    owner_users = {
      shared = {
        name          = "managed_owner"
        password      = "externally-managed-owner-password"
        generate_password = false
        manage_grants = false
        tls_option    = "NONE"
      }
    }

    users = {
      shared = {
        name           = "application_owner"
        grant          = "owner"
        resource_group = "user"
        password       = "externally-managed-user-password"
        generate_password = false
        manage_grants  = false
      }
    }
  }

  assert {
    condition     = length(mysql_database.this) == 1
    error_message = "Databases with create=false must not be managed."
  }

  assert {
    condition     = length(mysql_user.owner) == 1 && length(mysql_user.user) == 1
    error_message = "Independent owner and regular-user maps must preserve wrapper state addresses."
  }

  assert {
    condition     = length(random_password.owner) == 0 && length(random_password.user) == 0
    error_message = "Externally supplied passwords must disable generic password generation."
  }

  assert {
    condition     = length(mysql_grant.owner) == 0 && length(mysql_grant.readwrite) == 0 && length(mysql_grant.readonly) == 0
    error_message = "manage_grants=false must leave grants under wrapper ownership."
  }
}
