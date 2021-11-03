# Configuration to run LIQUIBASE migrations

Steps:
1. Create the docker image & container
   1. \# ./create_image.sh
2. Login to the container:
   1. \# ./start_session.sh
3. Edit the user_vars.yml and app_vars.yml files with the deploying user's credentials and database secrets
   1. (docker)# vi user_vars.yml
   1. (docker)# vi app_vars.yml
4. Get the Ansible collection
   1. (docker)# ./init_ansible.sh
5. Check the settings in the run_playbook.sh
   1. (docker)# vi run_playbook.sh
6. Run the liquibase playbook:
   1. (docker)# ./run_playbook.yml