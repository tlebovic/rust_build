###
### This Dockerfile is a base build image, useful for building rust
### projects
###

#######-----------------------Build Image--------------------------------#######
FROM rust:1.35 as build

# The OpenSSL version to use. We parameterize this because many Rust
# projects will fail to build with 1.1.
ARG OPENSSL_VERSION=1.0.2r

# Make sure PATH includes ~/.local/bin
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=839155
RUN echo 'PATH="$HOME/.local/bin:$PATH"' >> /etc/profile.d/user-local-path.sh

# Install Development Dependencies that are "missing"
# from the base rust Image
RUN apt-get update \
  && mkdir -p /usr/share/man/man1 \
  && apt-get install -y \
    musl-dev \
    musl-tools \
    file \
    nano \
    zlib1g-dev \
    pkgconf \
    linux-headers-amd64 \
    xutils-dev \
    git \
    xvfb \
    apt \
    locales \
    sudo \
    openssh-client \
    ca-certificates \
    tar \
    gzip \
    parallel \
    net-tools \
    netcat \
    unzip \
    zip \
    bzip2 \
    gnupg \
    curl \
    wget \
    make \
    cmake \
    clang \
    apt-utils \
    lsb-core && \
    rm -rf /var/lib/apt/lists/*


# OpenSSL 1.1 needs some linux headers to exists. They aren't installed by
# default to the directory of musl includes, so we must link them.
# OpenSSL 1.0 doesn't need these, but they won't do any harm.

RUN ln -s /usr/include/x86_64-linux-gnu/asm /usr/include/x86_64-linux-musl/asm && \
    ln -s /usr/include/asm-generic /usr/include/x86_64-linux-musl/asm-generic && \
    ln -s /usr/include/linux /usr/include/x86_64-linux-musl/linux


# Static linking for C++ code
RUN sudo ln -s "/usr/bin/g++" "/usr/bin/musl-g++"
RUN sudo ln -s "/usr/local/musl/include/openssl" "/usr/local/include/openssl"

# Build a static library version of OpenSSL & Libevent using musl-libc.
#
# We point /usr/local/musl/include/linux at some Linux kernel headers (not
# necessarily the right ones) in an effort to compile OpenSSL 1.1's "engine"
# component. It's possible that this will cause bizarre and terrible things to
# happen. There may be "sanitized" header
RUN echo "Building OpenSSL" && \
    ls /usr/include/linux && \
    sudo mkdir -p /usr/local/musl/include && \
    sudo ln -s /usr/include/linux /usr/local/musl/include/linux && \
    sudo ln -s /usr/include/x86_64-linux-gnu/asm /usr/local/musl/include/asm && \
    sudo ln -s /usr/include/asm-generic /usr/local/musl/include/asm-generic && \
    cd /tmp && \
    curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && \
    tar xvzf "openssl-$OPENSSL_VERSION.tar.gz" && cd "openssl-$OPENSSL_VERSION" && \
    env CC=musl-gcc ./Configure no-shared no-zlib -fPIC --prefix=/usr/local/musl -DOPENSSL_NO_SECURE_MEMORY linux-x86_64 && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make depend && \
    env C_INCLUDE_PATH=/usr/local/musl/include/ make && \
    sudo make install && \
    sudo rm /usr/local/musl/include/linux /usr/local/musl/include/asm /usr/local/musl/include/asm-generic && \
    rm -r /tmp/*


RUN echo "Building libevent" && \
     cd /tmp && \
     EVENT_VERSION=2.1.10 && \
     curl -LO "https://github.com/libevent/libevent/releases/download/release-2.1.10-stable/libevent-$EVENT_VERSION-stable.tar.gz" && \
     tar xzf "libevent-$EVENT_VERSION-stable.tar.gz" && cd "libevent-$EVENT_VERSION-stable" && \
     CC=musl-gcc ./configure --enable-static --with-pic --disable-shared --prefix=/usr/local/musl && \
     make && sudo make install && \
     rm -r /tmp/*

RUN echo "Building zlib" && \
    cd /tmp && \
    ZLIB_VERSION=1.2.11 && \
    curl -LO "http://zlib.net/zlib-$ZLIB_VERSION.tar.gz" && \
    tar xzf "zlib-$ZLIB_VERSION.tar.gz" && cd "zlib-$ZLIB_VERSION" && \
    CC=musl-gcc ./configure --static --prefix=/usr/local/musl && \
    make && sudo make install && \
    rm -r /tmp/*

# Install rust  musl libc for static binaries
RUN rustup target add x86_64-unknown-linux-musl

# Install couchbase sdk
#RUN wget http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-6-amd64.deb
#RUN dpkg -i couchbase-release-1.0-6-amd64.deb
#RUN apt-get update && \
#  apt-get install -y  libcouchbase-dev libcouchbase2-libevent build-essential

#Remove old libevent artifacts
RUN sudo rm /usr/lib/x86_64-linux-gnu/libev*

# Adding out library path to /etc/ld-musl-x86_64.path allows the dynamic linker
# to find musl libraries built by us.
RUN echo "/usr/local/musl/lib" >> /etc/ld-musl-x86_64.path


# SETTING THE ENV VARS FOR MUSL BUILDS - WHY THESE?
# PKG_CONFIG_PATH Some of the build.rs script of *-sys crates use pkg-config to probe for libs. (TODO)
# PKG_CONFIG_ALLOW_CROSS This tells the rust pkg-config crate to be enabled even when cross-compiling
# PKG_CONFIG_ALL_STATIC This tells the rust pkg-config crate to statically link the native dependencies
# PATH /musl/bin is needed because the build.rs that tells it the lib dir.

ENV OPENSSL_DIR=/usr/local/musl/ \
    OPENSSL_ROOT_DIR=/usr/local/musl/ \
    OPENSSL_STATIC=1 \
    CMAKE_CXX_COMPILER=/usr/bin/musl-g++ \
    CMAKE_C_COMPILER=/usr/bin/musl-gcc \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_INCLUDE_DIR=/usr/local/musl/include/ \
    X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_LIB_DIR=/usr/local/musl/lib/ \
    PKG_CONFIG_ALLOW_CROSS=true \
    PKG_CONFIG_ALL_STATIC=true \
    LIBZ_SYS_STATIC=1 \
    STATIC_LIBS=1 \
    LCB_BUILD_STATIC=1 \
    LCB_NO_PLUGINS=1 \
    BUILD_SHARED_LIBS=OFF \
    LIBEVENT_INCLUDE_DIR=/usr/local/musl/include/ \
    LIBEVENT_ROOT=/usr/local/musl/ \
    LIBEVENT_DIR=/usr/local/musl/lib/ \
    LIBEVENT_LIBRARIES=usr/local/musl/lib/ \
    LIBEVENT_INCLUDE_DIR=/usr/local/musl/include/ \
    TARGET=musl

WORKDIR /project_src

CMD ["/bin/sh"]
