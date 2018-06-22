FROM wodby/alpine:3.7-2.0.1

RUN set -ex; \
    \
    apk add --update --no-cache -t .backup-rundeps \
        make \
        py2-pip \
        tzdata; \
    \
    pip install -U awscli

COPY bin /usr/local/bin/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
