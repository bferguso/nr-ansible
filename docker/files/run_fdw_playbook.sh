#export APP_SOURCE=file:///home/kstrong/git/fsbwhse-db_bcgov/src/cd/playbooks/vars/playbook_vars.yml
export APP_SOURCE=https://bwa.nrs.gov.bc.ca/int/stash/projects/FSBWHSE/repos/fsbwhse-db/raw/src/cd/playbooks/vars/playbook_vars.yml?at=refs%2Fheads%2Ffeature%2FFSBWHSE-205
export CONFIG_TARGET=itcg
export APP_VERSION=6.21.2-SNAPSHOT
export EXTRA_VARS="--extra-vars @./app_secrets.yml --extra-vars pre_delta=1159 --extra-vars post_delta=1165"

./run_playbook.sh
