###
### This Dockerfile is a base build image, useful for building rust
### projects
###

#######-----------------------Build Image--------------------------------#######
FROM rust:1.36 as build

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
    libssl-dev \
    libevent-dev \
    ca-certificates \
    tar \
    gzip \
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




# Install couchbase sdk
RUN wget http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-6-amd64.deb
RUN dpkg -i couchbase-release-1.0-6-amd64.deb
RUN apt-get update && \
  apt-get install -y  libcouchbase-dev libcouchbase2-libevent build-essential


WORKDIR /project_src

CMD ["/bin/sh"]
