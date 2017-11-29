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
    backup-dir dir filepath zip exclude mark nice ionice
    rotate dir days 
    mirror-s3 filepath key_id access_key bucket region nice ionice   
    delete filepath 

default param values:
    days 7
        
EXAMPLES:   
    backup-dir dir=/home/user/data filepath=/mnt/archive.tar.gz zip="1" exclude="./dir1;./path/to/file"
    backup-dir dir=/home/user/data filepath=/mnt/archive.tar zip="" mark=".wodby"
    rotate dir=/tmp/data days=8 
    mirror-s3 filepath=/mnt/archive.tar key_id=ID access_key=KEY bucket=my-bucket region=us-east-1   
    delete filepath=/mnt/archive.tar
    nice 10
    ionice 7
    
```