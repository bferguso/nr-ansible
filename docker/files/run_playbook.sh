export ANSIBLE_COLLECTIONS_PATH=./collections
echo Using source: $APP_SOURCE
ansible-playbook \
	-i collections/ansible_collections/bcgov/nr/inventory/qed \
	--extra-vars playbook_vars_url=$APP_SOURCE \
	--extra-vars cdconf_target=$CONFIG_TARGET \
	--extra-vars cd_version=$APP_VERSION \
	$EXTRA_VARS \
	collections/ansible_collections/bcgov/nr/playbooks/liquibase.yml
