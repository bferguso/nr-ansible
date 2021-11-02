# TinyProxy Container

Table of Contents:

- [Build](#build)
- [Run](#run)
- [Run, Custom Config](#run-custom-config)
- [Stop, Start, Restart](#stop-start-or-restart)
- [Logs](#logs)

### Build

Build and tag an image.  The relative path (here `.`) is to the Dockerfile directory.

```
podman build . -t tinyproxy
```

### Run

Run a container.  Change the default port with `-p`.

```
podman run --name=tinyproxy -p 23128:8888 tinyproxy
```

### Run Custom Config

Run with custom config mounted in a volume at startup.  This is expected use.

```
podman run --name=tinyproxy -p 23128:8888 -v $(pwd)/conf/:/usr/local/etc/tinyproxy/:z tinyproxy
```

Note: SELinux distros (e.g. Red Hat, CentOS, Fedora) require `:z` for all volumes.

### Stop, Start or Restart

Stop, start or restart a container.  Useful for config changes.

```
podman stop tinyproxy
podman start tinyproxy
podman restart tinyproxy
```

### Logs

View the logs for a running container.  Follow (/tail) with `-f`.

```
podman logs tinyproxy
podman logs -f tinyproxy
```
