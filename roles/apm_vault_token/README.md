Role Name: apm_vault_token
=========

This role deploys the Vault token and environment for the Fluent Bit agent.

Requirements
------------

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
- name: deploy fluent-bit token and environment
  hosts: podman_servers
  gather_facts: false

  vars:
    ssh_user: "{{ lookup('env', 'SSH_USER') }}"
    ssh_pass: "{{ lookup('env', 'SSH_PASS') }}"
    ansible_become_password: "{{ lookup('env', 'BECOME_PASS') }}"
    artifactory_user: "{{ lookup('env', 'ARTIFACTORY_USER') }}"
    artifactory_pass: "{{ lookup('env', 'ARTIFACTORY_PASS') }}"
    vault_broker_token: "{{ lookup('env', 'VAULT_BROKER_TOKEN') }}"

  roles:
    - role: apm_vault_token
```

First, logon to Vault (use an account with access to the broker token path):

```
export VAULT_ADDR=https://vault-iit.apps.silver.devops.gov.bc.ca
export VAULT_TOKEN=$(vault login -method=oidc -format json | jq -r '.auth.client_token')
```

Do a dry-run:

```
andrwils@NC057944:~/projects/INFRAIO/mid-tier-ansible$ envconsul -config "conf/broker-token.hcl" ansible-playbook deploy-vault-token.yml -i inventory/dev/hosts.yml --check --diff
```

Run the playbook for real:
```
andrwils@NC057944:~/projects/INFRAIO/mid-tier-ansible$ envconsul -config "conf/broker-token.hcl" ansible-playbook deploy-vault-token.yml -i inventory/dev/hosts.yml
```