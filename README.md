<!-- PROJECT SHIELDS -->

[![Contributors](https://img.shields.io/github/contributors/bcgov/nr-ansible/)](/../../graphs/contributors)
[![Forks](https://img.shields.io/github/forks/bcgov/nr-ansible/)](/../../network/members)
[![Stargazers](https://img.shields.io/github/stars/bcgov/nr-ansible/)](/../../stargazers)
[![Issues](https://img.shields.io/github/issues/bcgov/nr-ansible/)](/../../issues)
[![MIT License](https://img.shields.io/github/license/bcgov/nr-ansible/)](/LICENSE.txt)
[![Lifecycle](https://img.shields.io/badge/Lifecycle-Stable-97ca00)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)


# Testing
## Create a Scenario
```
molecule init scenario fluent_bit --driver-name docker
```
in the molecule.yml file:
- update `platforms.name`, `platforms.image`
- add `provisioner.inventory`

## Starting toolset container
Make sure you have docker installed, and you can start a container with an interactive shell.
If you are on Windows, run directly from PowerShell (not from WSL2)
make sure the the root of the repository (`git rev-parse --show-toplevel`) is your current working directory

### Option 1
Start the container with mounting the root directory directly in an expected collections path:
```
docker run --rm -v "/var/run/docker.sock:/var/run/docker.sock" -v "${PWD}:/usr/share/ansible/collections/ansible_collections/bcgov/nr" -w "/usr/share/ansible/collections/ansible_collections/bcgov/nr" -it quay.io/ansible/toolset bash
```

### Option 2
we can start with mounting the root directory anywhere, and adding a symlink to the mounted path
```
docker run --rm -v "/var/run/docker.sock:/var/run/docker.sock" -v "${PWD}:/source" -w "/source"  -it quay.io/ansible/toolset bash
# after the container started, and you have a shell prompt:
mkdir -p /usr/share/ansible/collections/ansible_collections/bcgov
ln -s /source /usr/share/ansible/collections/ansible_collections/bcgov/nr
```

## Running a specific test
The inventoy can be created once, and changes can be applied as often as you need as you work on your role/module/etc.
The commands below are executed from within the toolset container previously started.
```
# Create inventory "machines"
molecule create --scenario-name fluent_bit

# Apply changes
molecule converge --scenario-name fluent_bit

# Destroy inventory "machines"
molecule destroy --scenario-name fluent_bit
```

## References
- https://molecule.readthedocs.io/en/latest/
- https://github.com/ericsysmin/ansible-collection-system
