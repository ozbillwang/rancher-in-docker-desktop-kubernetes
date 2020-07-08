# Usage

This repo is used to create rancher and add a kubernetes cluster in Rancher.

### Prerequisite

* Enable Kubernetes in Docker for Mac or Docker for Windows (Docker Desktop)

### Features

* Run Rancher UI
* change rancher admin’s password
* update server url in rancher
* Add an imported cluster in rancher

### Prerequisite

1) Enable Kubernetes in Docker for Mac or Docker for Windows (Docker Desktop)

2) Adjust docker engine memory

Default docker engine is set to use 2GB runtime memory, adjust it to 8GB if you can.

3) Add a shared folder in Docker Desktop

with this way, you can share the local directoy, for example, /data to all nodes as persistent volume.

### Get help

```
$ ./rancher.sh
Usage: ./rancher.sh [FLAGS] [ACTIONS]
  FLAGS:
    -h | --help | --usage   displays usage
    -q | --quiet            enabled quiet mode, no output except errors
    --debug                 enables debug mode, ignores quiet mode
  ACTIONS:
    create                create new Rancher & Kind cluster
    destroy               destroy Rancher & Kind cluster created by this script
  Examples:
    $ ./rancher.sh create
    $ ./rancher.sh destroy

```

### Create the stack

```
$ ./rkind.sh create
```

### destroy the stack

```
$ ./rkind.sh --destroy
```
