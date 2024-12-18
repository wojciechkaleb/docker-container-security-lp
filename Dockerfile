FROM alpine:3.21.0

LABEL org.opencontainers.image.authors="<psellars@gmail.com>"

RUN apk add --no-cache \
  curl \
  git \
  openssh-client \
  rsync

ENV VERSION=0.64.0
ARG HUGO_BINARY=hugo_${VERSION}_Linux-64bit.tar.gz
ENV PORT=1313

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]


WORKDIR /usr/local/src

RUN curl -OL \
  https://github.com/gohugoio/hugo/releases/download/v${VERSION}/${HUGO_BINARY} \
  && curl -OL https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_checksums.txt\
  && grep "$HUGO_BINARY" hugo_${VERSION}_checksums.txt | sha256sum -c - \
  && tar xf ${HUGO_BINARY} \
  && mv hugo /usr/local/bin/hugo \
  && addgroup -Sg 1000 hugo \
  && adduser -SG hugo -u 1000 -h /src hugo

WORKDIR /src


HEALTHCHECK --interval=10s --timeout=10s --retries=3 \
  CMD curl -I "0.0.0.0:${PORT}" || exit 1

EXPOSE $PORT
