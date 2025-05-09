resource "aws_cognito_user_pool" "bookstore_users" {
  name = "bookstore-user-pool"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  username_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

resource "aws_cognito_user_pool_client" "frontend" {
  name         = "frontend-client"
  user_pool_id = aws_cognito_user_pool.bookstore_users.id

  generate_secret = false

  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true

  supported_identity_providers = ["COGNITO"]

  callback_urls = ["https://${var.frontend_domain}"]
  logout_urls   = ["https://${var.frontend_domain}"]

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

token_validity_units {
  access_token  = "minutes"
  id_token      = "minutes"
  refresh_token = "days"
}
}

resource "aws_cognito_user_pool_domain" "cognito_domain" {
  domain       = var.cognito_domain
  user_pool_id = aws_cognito_user_pool.bookstore_users.id
}
