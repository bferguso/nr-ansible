Role Name: apm_agent
=========

This role deploys the base fluent bit install.

Requirements
------------

The role requires the following binaries on the target server (these are installed automatically as dependencies):
```
    - /sw_ux/bin/envconsul
    - /sw_ux/s6/bin/s6
```

For automatic retrieval of the broker token from Vault, you will also need the envconsul binary installed on the Ansible controller.  

Role Variables
--------------

The role requires the following environment variables:
```
    - ssh_user: "{{ lookup('env', 'SSH_USER') }}"
    - ssh_pass: "{{ lookup('env', 'SSH_PASS') }}"
    - ansible_become_password: "{{ lookup('env', 'BECOME_PASS') }}"
    - artifactory_user: "{{ lookup('env', 'ARTIFACTORY_USER') }}"
    - artifactory_pass: "{{ lookup('env', 'ARTIFACTORY_PASS') }}"
    - vault_broker_token: "{{ lookup('env', 'VAULT_BROKER_TOKEN') }}"
```
NOTES:
* If you are setting the above variables by hand, be sure to export them.
* The Vault broker token is required for successful deployment. The current version of the broker token is stored in Vault. You can run the playbook using the envconsul binary to grab the broker token automatically (see example below). 
* You can re-use the current version of the broker token, but note that it has a limited time to live (TTL).
* Use the vault token lookup command to confirm the broker token's TTL.
* You can always generate a new broker token at any time and deploy it.
* If generating a new broker token, be sure to update the new token in Vault (path: apps_shared/prod/vault/broker), then revoke the old one.

Example Playbook
----------------

This is an example playbook for deploying fluent bit:

```
- name: deploy fluent-bit
  hosts: fluent_bit
  gather_facts: false

  vars:
    ssh_user: "{{ lookup('env', 'SSH_USER') }}"
    ssh_pass: "{{ lookup('env', 'SSH_PASS') }}"
    ansible_become_password: "{{ lookup('env', 'BECOME_PASS') }}"
    artifactory_user: "{{ lookup('env', 'ARTIFACTORY_USER') }}"
    artifactory_pass: "{{ lookup('env', 'ARTIFACTORY_PASS') }}"
    vault_broker_token: "{{ lookup('env', 'VAULT_BROKER_TOKEN') }}"

  roles:
    - role: apm_agent
```

First, logon to Vault (use an account with access to the broker token path):

```
export VAULT_ADDR=https://vault-iit.apps.silver.devops.gov.bc.ca
export VAULT_TOKEN=$(vault login -method=oidc -format json | jq -r '.auth.client_token')
```

Do a dry-run:

```
andrwils@NC057944:~/projects/INFRAIO/mid-tier-ansible$ envconsul -config "conf/broker-token.hcl" ansible-playbook playbooks/deploy-fluent-bit.yml -i inventory/dev/hosts.yml --check --diff
```

Run the playbook for real, but only deploy to one server:
```
andrwils@NC057944:~/projects/INFRAIO/mid-tier-ansible$ envconsul -config "conf/broker-token.hcl" ansible-playbook playbooks/deploy-fluent-bit.yml -i inventory/dev/hosts.yml --limit skittles
```

Run the playbook for real, but deploy to both non-prod reverse proxy servers:
```
andrwils@NC057944:~/projects/INFRAIO/mid-tier-ansible$ envconsul -config "conf/broker-token.hcl" ansible-playbook playbooks/deploy-fluent-bit.yml -i inventory/dev/hosts.yml
```