vault {
  address = "{{ vault_addr }}"
  token = "{{ vault_token }}"
  renew_token = true
}

secret {
    no_prefix = true
    path = "{{ secrets_path }}"
}
