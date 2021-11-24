docker build . --tag bcgov:lb-deployer
docker run -dit -v ~/.m2/repository:/apps_ux/repo -v ~/git:/home/kstrong/git --name lb-deployer bcgov:lb-deployer
