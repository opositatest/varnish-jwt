FROM varnish:6.5.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    automake \
    autotools-dev \
    build-essential \
    ca-certificates \
    curl \
    git \
    libedit-dev \
    libjemalloc-dev \
    libmhash-dev \
    libncurses-dev \
    libpcre3-dev \
    libtool \
    pkg-config \
    python3 \
    python3-docutils \
    python3-sphinx \
    varnish-dev=6.5.1~buster-1 \
    libssl-dev \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENV LIBVMOD_CRYPTO_VERSION=6.5

RUN cd /usr/local/src/ && \
    curl -sfLO https://code.uplex.de/uplex-varnish/libvmod-crypto/-/archive/${LIBVMOD_CRYPTO_VERSION}/libvmod-crypto-${LIBVMOD_CRYPTO_VERSION}.tar.gz && \
    tar -xzf libvmod-crypto-${LIBVMOD_CRYPTO_VERSION}.tar.gz && \
    cd libvmod-crypto-${LIBVMOD_CRYPTO_VERSION} && \
    ./bootstrap && \
    ./configure && \
    make install && \
    cd /usr/local/src && \
    rm -rf libvmod-crypto* && \
    ldconfig


#
# install libvmod-digest
#
ENV LIBVMOD_DIGEST_BRANCH=6.5

RUN cd /usr/local/src/ && \
    git clone -b ${LIBVMOD_DIGEST_BRANCH} https://github.com/varnish/libvmod-digest.git && \
    cd libvmod-digest && \
    ./autogen.sh && \
    ./configure && \
    make install && \
    cd /usr/local/src && \
    rm -rf libvmod-digest && \
    ldconfig

COPY /varnish/ /etc/varnish/
