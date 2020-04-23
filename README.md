# Simple Backup Container Image

[![Build Status](https://travis-ci.org/wodby/backup.svg?branch=master)](https://travis-ci.org/wodby/backup)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/backup.svg)](https://hub.docker.com/r/wodby/backup)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/backup.svg)](https://hub.docker.com/r/wodby/backup)
[![Docker Layers](https://images.microbadger.com/badges/image/wodby/backup.svg)](https://microbadger.com/images/wodby/backup)

## Docker Images

For better reliability we release images with stability tags (`wodby/backup:X.X.X`) which correspond to [git tags](https://github.com/wodby/backup/releases). We strongly recommend using images only with stability tags. 

Overview:

* All images based on Alpine Linux
* Base image: [wodby/alpine](https://github.com/wodby/alpine)
* [Travis CI builds](https://travis-ci.org/wodby/backup) 
* [Docker Hub](https://hub.docker.com/r/wodby/backup)

Supported tags and respective `Dockerfile` links:

* `latest` [_(Dockerfile)_](https://github.com/wodby/backup/tree/master/Dockerfile)

## Actions

Usage:
```
make COMMAND [params ...]
 
commands:
    backup-dir dir filepath [zip exclude mark]
    rotate dir [days] 
    upload provider filepath key secret bucket scope [max_concurrent_requests max_bandwidth storage_class]
    backup-and-upload dir provider key secret bucket scope [max_concurrent_requests max_bandwidth storage_class] 
    delete filepath 

default param values:
    days 7
    max_concurrent_requests 1
    max_bandwidth
```
