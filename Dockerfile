FROM wodby/alpine:3.7-1.2.0

RUN set -ex; \
    \
    apk add --update --no-cache -t .backup-rundeps \
        make \
        py2-pip \
        tzdata; \
    \
    pip install -U awscli

COPY actions/ /usr/local/bin/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
