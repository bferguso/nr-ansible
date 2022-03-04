vault {
  address = "{{ vault_addr }}"
  renew_token = true
  retry {
    enabled = true
    attempts = 12
    backoff = "250ms"
    max_backoff = "1m"
  }
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
    custom = ["HTTP_PROXY={{ fluent_bit_http_proxy }}","NO_PROXY={{ vault_addr }},169.254.169.254"]
{% endif %}
  }
}
