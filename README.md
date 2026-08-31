# Simple Backup Container Image

[![Build Status](https://github.com/wodby/backup/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/backup/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/backup.svg)](https://hub.docker.com/r/wodby/backup)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/backup.svg)](https://hub.docker.com/r/wodby/backup)

## Docker Images

For better reliability we release images with stability tags (`wodby/backup:X.X.X`) which correspond to [git tags](https://github.com/wodby/backup/releases). We strongly recommend using images only with stability tags. 

Overview:

* All images are based on Alpine Linux
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
    upload provider filepath bucket [destination max_concurrent_requests max_bandwidth storage_class content_disposition region endpoint_url]
    backup-and-upload provider dir bucket destination [gzip max_concurrent_requests max_bandwidth storage_class content_disposition region endpoint_url]
    delete filepath 
    import source destination [owner group allowed delete] 

default param values:
    days 7
    max_concurrent_requests 1
    max_bandwidth

Notes:
* pass credentials through container environment variables instead of `key` and `secret` make arguments:
  * AWS and S3-compatible: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and optional `AWS_SESSION_TOKEN`
  * GCP: `GOOGLE_APPLICATION_CREDENTIALS` for a mounted service-account file, or `GCP_SA` for its base64-encoded contents
  * Azure: `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY`
* the legacy `key` and `secret` make arguments remain supported for compatibility, but can expose credentials through process arguments
* `provider=aws` uses the AWS CLI S3 flow and defaults `storage_class` to `STANDARD`
* `provider=azure` uses `rclone` Azure Blob upload, where `bucket` is the container name and `storage_class` maps to the Azure access tier (`hot`, `cool`, `cold`, `archive`)
* `provider=azure` accepts `AZURE_STORAGE_ENDPOINT` or `endpoint_url` for custom Blob endpoints such as Azurite
* any non-`aws`, non-`gcp` provider is treated as S3-compatible and requires `endpoint_url`
* S3 uploads use AWS CLI `path` addressing style for broader compatibility
```
