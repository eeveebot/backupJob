FROM docker.io/alpine:3

RUN set -exu \
  && apk add \
    --no-cache \
    bash \
    coreutils \
    tar \
    s3cmd

COPY src/backup.sh /usr/local/bin/backup.sh
COPY src/restore.sh /usr/local/bin/restore.sh

RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/restore.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/usr/local/bin/backup.sh"]
