FROM alpine:3.21.0

ARG BUILD_DATE
ARG IMAGE_VERSION
ARG COMMIT_SHA
ARG BUILD_VERSION=0.0.1

LABEL org.opencontainers.image.authors="<kalebasiakw@gmail.com>"
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.revision=${COMMIT_SHA}
LABEL org.opencontainers.image.version=${IMAGE_VERSION}
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.source=https://github.com/wojciechkaleb/docker-container-security-lp
LABEL org.opencontainers.image.title=MannerHugoBuilder

ENV VERSION=0.64.0
ARG HUGO_BINARY=hugo_${VERSION}_Linux-64bit.tar.gz
ENV PORT=1313


RUN addgroup -Sg 1000 hugo && adduser -SG hugo -u 1000 -h /src hugo


RUN apk add --no-cache \
  curl \
  git \
  openssh-client \
  rsync

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]


WORKDIR /usr/local/src

RUN curl -OL \
  https://github.com/gohugoio/hugo/releases/download/v${VERSION}/${HUGO_BINARY} \
  && curl -OL https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_checksums.txt\
  && grep "$HUGO_BINARY" hugo_${VERSION}_checksums.txt | sha256sum -c - \
  && tar xf ${HUGO_BINARY} \
  && mv hugo /usr/local/bin/hugo

USER hugo
WORKDIR /src


HEALTHCHECK --interval=5s --timeout=5s \
  CMD hugo env || exit 1

EXPOSE $PORT
