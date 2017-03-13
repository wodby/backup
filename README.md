# Simple backup container

[![Build Status](https://travis-ci.org/wodby/backup.svg?branch=master)](https://travis-ci.org/wodby/backup)
[![Docker Pulls](https://img.shields.io/docker/pulls/backup/php.svg)](https://hub.docker.com/r/wodby/backup)
[![Docker Stars](https://img.shields.io/docker/stars/backup/php.svg)](https://hub.docker.com/r/wodby/backup)

[![Wodby Slack](https://www.google.com/s2/favicons?domain=www.slack.com) Join us on Slack](https://slack.wodby.com/)

## Supported tags and respective `Dockerfile` links:

- [`latest` (*Dockerfile*)](https://github.com/wodby/backup/tree/master/Dockerfile)

## Actions

Usage:
```
make COMMAND [params ...]
 
commands:
    backup-dir dir=<directory to backup> filepath=</mnt/backup-file.tar.gz>   
    mirror-s3 filepath=</path/to/archive.tar.gz> key_id=<AWS KEY ID> access_key=<AWS ACCESS KEY> bucket=<AWS S3 BUCKET NAME> region=<AWS REGION>   

```