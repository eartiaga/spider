################################
# HEADLESS SPIDEROAK-ONE SETUP #
################################

ARG BASE_IMAGE_VERSION=3.17

FROM alpine:${BASE_IMAGE_VERSION}

ARG SPIDEROAK_VERSION=7.5.0
ARG SPIDEROAK_UID=""
ARG SPIDEROAK_GID=""

ARG SPIDEROAK_USER="spider"
ARG SPIDEROAK_HOME="/home/${SPIDEROAK_USER}"
ARG SPIDEROAK_BACKUPDIR="/BACKUP"
ARG SPIDEROAK_STATEDIR="/STATE"

RUN apk update && \
    apk add curl gcompat && \
    rm -rf /var/cache/apk/* /var/lib/apk/* /etc/apk/cache/* && \
    mkdir /app && \
    curl "https://spideroak-releases.s3.us-east-2.amazonaws.com/SpiderOakONE-${SPIDEROAK_VERSION}-slack_tar_x64.tgz" -o /app/SpiderOakONE.tgz && \
    cd / && \
    tar xvzf /app/SpiderOakONE.tgz && \
    adduser --system --disabled-password --gecos 'SpiderOak ONE' --home "${SPIDEROAK_HOME}" -u "${SPIDEROAK_UID}" "${SPIDEROAK_USER}" && \
    mkdir -p "${SPIDEROAK_HOME}" && \
    mkdir -p "${SPIDEROAK_HOME}/.config" && \
    chmod -R 0775 "${SPIDEROAK_HOME}" && \
    mkdir -p "${SPIDEROAK_BACKUPDIR}" && \
    mkdir -p "${SPIDEROAK_STATEDIR}" && \
    ln -s "${SPIDEROAK_STATEDIR}" "${SPIDEROAK_HOME}/.config/SpiderOakONE"

ENV SPIDEROAK_DEVICE_NAME=""
ENV SPIDEROAK_REINSTALL="false"
ENV SPIDEROAK_BACKUPDIR="${SPIDEROAK_BACKUPDIR}"
ENV SPIDEROAK_STATEDIR="${SPIDEROAK_STATEDIR}"
ENV HOME="{SPIDEROAK_HOME}"
COPY ./setup.sh /app/setup
COPY ./info.sh /app/info
COPY ./select.sh /app/select
COPY ./shutdown.sh /app/shutdown
COPY ./launch.sh /app/launch
USER "${SPIDEROAK_USER}"
WORKDIR "${SPIDEROAK_HOME}"
ENTRYPOINT [ "/bin/sh" ]
CMD [ "/app/launch" ]

