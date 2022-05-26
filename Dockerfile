FROM docker.io/tiredofit/alpine:3.16
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ENV COUCHDB_VERSION=3.2.2 \
    ERLANG_VERSION=OTP-24.3.4 \
    ERLANG_REBAR_VERSION=3.18.0 \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    IMAGE_NAME="tiredofit/couchdb" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-couchdb/"

RUN set -ex && \
    addgroup -g 5984 couchdb && \
    adduser -S -D -H -h /data -s /sbin/nologin -G couchdb -u 5984 couchdb && \
    apk update && \
    apk upgrade && \
    ## Build Erlang
    apk add -t .erlang-build-deps \
                dpkg-dev dpkg \
                gcc \
                g++ \
                git \
                libc-dev \
                linux-headers \
                make \
                autoconf \
                ncurses-dev \
                openssl-dev \
                unixodbc-dev \
                lksctp-tools-dev \
                tar \
                && \
    \
    apk add -t .erlang-run-deps \
                lksctp-tools \
                && \
    \
    apk add -t .couchdb-build-deps \
                abuild \
                alpine-sdk \
                curl-dev \
                elixir \
                make \
                icu-dev \
                mozjs91-dev \
                && \
    \
    apk add -t .couchdb-run-deps \
                git \
                icu-libs \
                && \
    \
    git clone https://github.com/erlang/otp /usr/src/erlang && \
    cd /usr/src/erlang && \
    git checkout ${ERLANG_VERSION} && \
    ./otp_build autoconf && \
    gnuArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" && \
	./configure --build="$gnuArch" && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
	make install && \
	find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf && \
    find /usr/local -name src | xargs -r find | grep -v '\.hrl$' | xargs rm -v || true && \
    find /usr/local -name src | xargs -r find | xargs rmdir -vp || true && \
	scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all && \
	scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded && \
    \
    ## Build Erlang Rebar3
    git clone https://github.com/erlang/rebar3 /usr/src/erlang-rebar3 && \
    cd /usr/src/erlang-rebar3 && \
    git checkout ${ERLANG_REBAR_VERSION} && \
    HOME=$PWD ./bootstrap && \
    install -v ./rebar3 /usr/local/bin/ && \
    \
    ## Build CouchDB
    git clone https://github.com/apache/couchdb/ /usr/src/couchdb && \
    cd /usr/src/couchdb && \
    git checkout ${COUCHDB_VERSION} && \
    ./configure \
                --disable-fauxton \
                --disable-docs  \
                --spidermonkey-version 91 \
                && \
    \
    make -j$(getconf _NPROCESSORS_ONLN) release && \
    cp -R rel/couchdb /opt/ && \
    chown -R couchdb:couchdb /opt/couchdb && \
    chmod -R 0644 /opt/couchdb/etc && \
    rm -rf /usr/src/* && \
    apk del .erlang-build-deps .couchdb-build-deps && \
    rm -rf /tmp/* /var/cache/apk/*

ADD install  /
