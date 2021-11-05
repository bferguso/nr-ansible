export ANSIBLE_COLLECTIONS_PATH=./collections
ansible-playbook \
	-i collections/ansible_collections/bcgov/nr/inventory/qed \
	--extra-vars playbook_vars_url=https://bwa.nrs.gov.bc.ca/int/stash/projects/FFS/repos/ffs-db/raw/src/cd/playbooks/vars/playbook_vars.yml?at=refs%2Fheads%2Ffeature%2F7.4.2_new \
	--extra-vars cdconf_target=dev \
	--extra-vars cd_version="7.4.2-SNAPSHOT" \
	collections/ansible_collections/bcgov/nr/playbooks/liquibase.yml