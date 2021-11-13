vault {
  address = "{{ vault_addr }}"
  renew_token = true
}

secret {
    no_prefix = true
    path = "apps/prod/fluent/fluent-bit"
}

exec {
  command = "{{ apm_agent_home }}/bin/fluent-bit -c {{ apm_agent_home }}/conf/fluent-bit.conf"
  splay = "5s"
  env {
    pristine = false
{% if fluent_bit_http_proxy is defined %}
    custom = ["HTTP_PROXY={{ fluent_bit_http_proxy }}","NO_PROXY={{ vault_addr }}"]
{% endif %}
  }
}
