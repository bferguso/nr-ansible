### Build Fluent Bit package for NRM servers

Use this Dockerfile and build.sh script to build a Fluent Bit package and upload it to Artifactory. The package can then
be used by the Fluent Bit Jenkins job to deploy to NRM servers.

## Set environment

First set your Artifactory username and password. The username is your email address.

```
read ARTIFACTORY_USER
read -s ARTIFACTORY_PASS
```

Export the variables.

```
export ARTIFACTORY_USER
export ARTIFACTORY_PASS
```

## Build and upload package

Run artifactory/fluent-bit/build.sh and pass it the version of Fluent Bit you want to build.

```
artifactory/fluent-bit/build.sh 1.9.1
```
