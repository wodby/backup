# Simple Backup Container Image

[![Build Status](https://github.com/wodby/backup/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/backup/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/backup.svg)](https://hub.docker.com/r/wodby/backup)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/backup.svg)](https://hub.docker.com/r/wodby/backup)

## Docker Images

For better reliability we release images with stability tags (`wodby/backup:X.X.X`) which correspond to [git tags](https://github.com/wodby/backup/releases). We strongly recommend using images only with stability tags. 

Overview:

* All images based on Alpine Linux
* Base image: [wodby/alpine](https://github.com/wodby/alpine)
* [Docker Hub](https://hub.docker.com/r/wodby/backup)

Supported tags and respective `Dockerfile` links:

* `latest` [_(Dockerfile)_](https://github.com/wodby/backup/tree/master/Dockerfile)

## Actions

Usage:
```
make COMMAND [params ...]
 
commands:
    backup-dir dir filepath [gzip exclude mark]
    rotate dir [days] 
    upload provider filepath key secret bucket [destination max_concurrent_requests max_bandwidth storage_class content_disposition]
    backup-and-upload dir provider key secret bucket destination [gzip max_concurrent_requests max_bandwidth storage_class content_disposition] 
    delete filepath 
    import source destination owner group  

default param values:
    days 7
    max_concurrent_requests 1
    max_bandwidth
```
