ansible-galaxy collection install git+https://www.github.com/bferguso/nr-ansible,feature/liquibase -p ./collections
export ANSIBLE_COLLECTIONS_PATH=./collections
#curl https://bferguso%40gov.bc.ca:1stTr1p1n%40Wh1l3\!\!@bwa.nrs.gov.bc.ca/int/stash/projects/FFS/repos/ffs-db/raw/src/cd/playbooks/vars/DEFAULT.yml?at=refs%2Fheads%2Ffeature%2F7.4.2_new
#ansible-playbook --extra-vars @./playbook_vars.yml --extra-vars @./user_vars.yml collections/ansible_collections/bcgov/nr/playbooks/bootstrap.yml