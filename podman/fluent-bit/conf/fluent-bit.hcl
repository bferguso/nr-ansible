vault {
  address = "${VAULT_ADDR}"
  renew_token = true
}

secret {
    no_prefix = true
    path = "apps/prod/fluent/fluent-bit"
}
