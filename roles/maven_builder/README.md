Role Name: maven_builder
=========

This role deploys configuration for Maven builder containers.

Requirements
------------

At this time, the role only deploys configuration and expects a container image to be available.  

Role Variables
--------------

The role requires the following environment variables:
```
    - ssh_user: "{{ lookup('env', 'SSH_USER') }}"
    - ssh_pass: "{{ lookup('env', 'SSH_PASS') }}"
    - ansible_become_password: "{{ lookup('env', 'BECOME_PASS') }}"
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

This is an example playbook for deploying the maven builder:

```
- name: deploy maven builder
  hosts: maven_builder
  gather_facts: no

  collections:
    - bcgov.nr

  vars:
    ssh_user: "{{ lookup('env', 'SSH_USER') }}"
    ssh_pass: "{{ lookup('env', 'SSH_PASS') }}"
    ansible_become_password: "{{ lookup('env', 'BECOME_PASS') }}"
    vault_broker_token: "{{ lookup('env', 'VAULT_BROKER_TOKEN') }}"

  vars_files:
    - inventory/dev/group_vars/maven_builder.yml

  roles:
    - role: maven_builder
```

First, logon to Vault (use an account with access to the broker token path):

```
export VAULT_ADDR=https://vault-iit.apps.silver.devops.gov.bc.ca
export VAULT_TOKEN=$(vault login -method=oidc -format json | jq -r '.auth.client_token')
```

Install the Ansible collection so the role is available to your playbook:

```
ansible-galaxy collection install git+https://github.com/bcgov/nr-ansible.git -p ./collections
```

Do a dry-run:

```
envconsul -config "conf/broker-token.hcl" ansible-playbook maven-builder.yml -i inventory/dev/hosts.yml --limit payload --check --diff
```

Run the playbook for real:
```
envconsul -config "conf/broker-token.hcl" ansible-playbook maven-builder.yml -i inventory/dev/hosts.yml --limit payload
```