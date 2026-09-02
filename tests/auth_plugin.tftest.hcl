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
      name = "appdb"
    }
  }
}

run "passwordless_plugins_suppress_generation" {
  command = plan

  variables {
    users = {
      aad = {
        name        = "aad_user"
        grant       = "readwrite"
        databases   = ["appdb"]
        auth_plugin = "aad_auth"
        aad_identity = {
          type     = "user"
          identity = "app@contoso.com"
        }
      }
      awsauth = {
        name        = "aws_user"
        grant       = "readonly"
        databases   = ["appdb"]
        auth_plugin = "AWSAuthenticationPlugin"
      }
      nologin = {
        name        = "nologin_user"
        grant       = "readonly"
        databases   = ["appdb"]
        auth_plugin = "mysql_no_login"
      }
    }
    password_rotation_period = 90
  }

  assert {
    condition     = length(random_password.user) == 0
    error_message = "Passwordless auth plugins must not generate a password."
  }

  assert {
    condition     = length(time_rotating.user) == 0
    error_message = "Passwordless auth plugins must not schedule password rotation."
  }

  assert {
    condition     = length(mysql_user.user) == 3
    error_message = "Passwordless accounts must still be created."
  }

  assert {
    condition     = length(output.user_passwords) == 0
    error_message = "Passwordless accounts must be omitted from user_passwords so wrappers store no unusable secret."
  }

  assert {
    condition     = length(output.user_usernames) == 3
    error_message = "Passwordless accounts must still be reported in user_usernames."
  }
}

run "auth_string_suppresses_generation" {
  command = plan

  variables {
    users = {
      hashed = {
        name        = "hashed_user"
        grant       = "readwrite"
        databases   = ["appdb"]
        auth_plugin = "caching_sha2_password"
        auth_string = "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19"
      }
      hashed_alias = {
        name               = "hashed_alias_user"
        grant              = "readonly"
        databases          = ["appdb"]
        auth_plugin        = "mysql_native_password"
        auth_string_hashed = "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19"
      }
    }
  }

  assert {
    condition     = length(random_password.user) == 0
    error_message = "A supplied auth_string is the credential; no password may be generated."
  }

  assert {
    condition     = length(output.user_passwords) == 0
    error_message = "Accounts authenticating by auth_string must be omitted from user_passwords."
  }
}

run "normal_plugin_still_generates_password" {
  command = plan

  variables {
    users = {
      normal = {
        name        = "normal_user"
        grant       = "readwrite"
        databases   = ["appdb"]
        auth_plugin = "caching_sha2_password"
      }
      plain = {
        name      = "plain_user"
        grant     = "readonly"
        databases = ["appdb"]
      }
    }
    # Non-zero so time_rotating.user has instances: random_password's
    # replace_triggered_by cannot resolve an empty resource under `tofu test`.
    password_rotation_period = 90
  }

  assert {
    condition     = length(random_password.user) == 2
    error_message = "caching_sha2_password without auth_string still takes IDENTIFIED ... BY, so generation must continue."
  }

  assert {
    condition     = length(output.user_passwords) == 2
    error_message = "Accounts that do hold a password must still be reported in user_passwords."
  }
}

run "owner_map_honours_the_same_gate" {
  command = plan

  variables {
    owner_users = {
      aad = {
        name        = "aad_owner"
        databases   = ["appdb"]
        auth_plugin = "aad_auth"
        aad_identity = {
          identity = "owner@contoso.com"
        }
      }
      normal = {
        name      = "normal_owner"
        databases = ["appdb"]
      }
    }
    password_rotation_period = 30
  }

  assert {
    condition     = length(random_password.owner) == 1
    error_message = "Only the non-suppressed owner may generate a password."
  }

  assert {
    condition     = length(time_rotating.owner) == 1
    error_message = "Only the non-suppressed owner may be scheduled for rotation."
  }

  assert {
    condition     = length(output.owner_passwords) == 1 && !contains(keys(output.owner_passwords), "aad")
    error_message = "The aad_auth owner must be omitted from owner_passwords."
  }

  assert {
    condition     = length(mysql_user.owner) == 2
    error_message = "Both owner accounts must still be created."
  }
}
