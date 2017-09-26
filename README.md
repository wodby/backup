# Simple Backup Container Image

[![Build Status](https://travis-ci.org/wodby/backup.svg?branch=master)](https://travis-ci.org/wodby/backup)
[![Docker Pulls](https://img.shields.io/docker/pulls/backup/php.svg)](https://hub.docker.com/r/wodby/backup)
[![Docker Stars](https://img.shields.io/docker/stars/backup/php.svg)](https://hub.docker.com/r/wodby/backup)

## Supported tags and respective `Dockerfile` links:

- [`latest` (*Dockerfile*)](https://github.com/wodby/backup/tree/master/Dockerfile)

## Actions

Usage:
```
make COMMAND [params ...]
 
commands:
    backup-dir dir=<directory to backup> filepath=</mnt/backup-file.tar.gz> zip="" exclude="./dir1;./path/to/file"
    rotate dir=<path to directory> days=<# of days> 
    mirror-s3 filepath=</path/to/archive.tar.gz> key_id=<AWS KEY ID> access_key=<AWS ACCESS KEY> bucket=<AWS S3 BUCKET NAME> region=<AWS REGION>   
    delete filepath=</path/to/file> 

default param values:
    days 7
```