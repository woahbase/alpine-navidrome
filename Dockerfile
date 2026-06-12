# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE}
#
ARG SRCARCH
ARG VERSION
#
ENV \
    GODEBUG="asyncpreemptoff=1" \
    ND_CONFIGFILE=/data/navidrome.toml \
    ND_DATAFOLDER=/data \
    ND_MUSICFOLDER=/music \
    ND_BASEURL="/navidrome" \
    ND_PORT=4533 \
    ND_ENABLEINSIGHTSCOLLECTOR=false \
    ND_ENABLEWEBPENCODING=true
    # ND_SCANSCHEDULE=1h \
    # ND_LOGLEVEL=info \
    # ND_SESSIONTIMEOUT=24h \
#
RUN set -xe \
    && apk add -Uu --no-cache --purge \
        curl \
        ffmpeg \
        libwebp \
        libwebpdemux \
        libwebpmux \
        mpv \
        sqlite \
        # taglib \
    && for lib in libwebp libwebpdemux libwebpmux; \
        do \
            target=$(ls /usr/lib/$lib.so.* 2>/dev/null | head -1) \
            && [ -n "$target" ] \
            && ln -sf "$target" /usr/lib/$lib.so; \
        done \
    && curl -jSLN \
        https://github.com/navidrome/navidrome/releases/download/v${VERSION}/navidrome_${VERSION}_${SRCARCH}.tar.gz \
        | tar xvz -C /usr/local/bin \
    && apk del --purge \
        curl \
    && touch /.nddockerenv \
    && rm -f /var/cache/apk/* /tmp/*
#
COPY root/ /
#
VOLUME ${ND_DATAFOLDER} ${ND_MUSICFOLDER}
#
EXPOSE ${ND_PORT}
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    wget -q -T '2' -O /dev/null ${HEALTHCHECK_URL:-"http://localhost:${ND_PORT}${ND_BASEURL}/ping"} || exit 1
#
ENTRYPOINT ["/init"]
