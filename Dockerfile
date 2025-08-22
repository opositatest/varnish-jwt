FROM debian:bookworm-slim

USER root

ENV VARNISH_PACKAGE_VERSION=7.7.3-1~bookworm
ENV LIBVMOD_CRYPTO_VERSION=master

RUN export DEBCONF_NOWARNINGS=yes && \
    echo "====INSTALL BASIC PACKAGES====" && \
    apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    > /dev/null && \
    echo "====INSTALL VARNISH ${VARNISH_PACKAGE_VERSION}====" && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish77/script.deb.sh | bash > /dev/null && \
    apt-get install -y varnish=${VARNISH_PACKAGE_VERSION} varnish-dev=${VARNISH_PACKAGE_VERSION} > /dev/null && \
    echo "====INSTALL DEPENDENCIES====" && \
    apt-get install -y --no-install-recommends \
    automake \
    build-essential \
    libtool \
    python3-docutils \
    libssl-dev \
    > /dev/null && \
    echo "====DOWNLOAD VMOD-CRYPTO====" && \
    cd /usr/local/src/ && \
    curl -sfLO https://code.uplex.de/uplex-varnish/libvmod-crypto/-/archive/${LIBVMOD_CRYPTO_VERSION}/libvmod-crypto-${LIBVMOD_CRYPTO_VERSION}.tar.gz && \
    tar -xzf libvmod-crypto-${LIBVMOD_CRYPTO_VERSION}.tar.gz && \
    echo "====BOOTSTRAP VMOD-CRYPTO====" && \
    cd /usr/local/src/libvmod-crypto-${LIBVMOD_CRYPTO_VERSION} && \
    ./bootstrap > /dev/null && \
    echo "====CONFIGURE VMOD-CRYPTO====" && \
    ./configure >/dev/null && \
    echo "====MAKE INSTALL VMOD-CRYPTO====" && \
    make install 2>/dev/null 1>/dev/null && \
    echo "====LDCONFIG====" && \
    cd /usr/local/src && \
    rm -rf libvmod-crypto* && \
    ldconfig > /dev/null && \
    echo "====CLEAN SYSTEM====" && \
    apt-get purge -y varnish-dev > /dev/null && \
    apt-get clean > /dev/null && \
    rm -rf /var/lib/apt/lists/*

COPY /varnish/ /etc/varnish/

COPY docker-varnish-entrypoint /usr/local/bin/

WORKDIR /etc/varnish

ENTRYPOINT ["/usr/local/bin/docker-varnish-entrypoint"]

USER varnish
EXPOSE 80 8443
CMD []