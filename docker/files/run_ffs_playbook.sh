export APP_SOURCE=https://bwa.nrs.gov.bc.ca/int/stash/projects/FFS/repos/ffs-db/raw/src/cd/playbooks/vars/playbook_vars.yml?at=refs%2Fheads%2Ffeature%2F7.4.3
export CONFIG_TARGET=qed
export APP_VERSION=7.4.3-SNAPSHOT
export EXTRA_VARS="--extra-vars @./app_secrets.yml"

./run_playbook.sh
