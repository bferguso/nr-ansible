vault {
  address = "{{ vault_addr }}"
  renew_token = true
}

secret {
    no_prefix = true
    path = "apps/prod/fluent/fluent-bit"
}
