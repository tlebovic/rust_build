###
### This Dockerfile is a base build image, useful for building rust
### projects
###

#######-----------------------Build Image--------------------------------#######
FROM rust:1.35 as build

# Make sure PATH includes ~/.local/bin
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=839155
RUN echo 'PATH="$HOME/.local/bin:$PATH"' >> /etc/profile.d/user-local-path.sh

# Install Development Dependencies that are "missing"
# from the base rust Image
RUN apt-get update \
  && mkdir -p /usr/share/man/man1 \
  && apt-get install -y \
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
    libevent-dev \
    libssl-dev \
    clang \
    apt-utils \
    lsb-core

# Static linking for C++ code
RUN sudo ln -s "/usr/bin/g++" "/usr/bin/musl-g++"

# Install musl libc for static binaries
RUN apt-get install -y musl musl-dev musl-tools
RUN rustup target add x86_64-unknown-linux-musl

# Install couchbase sdk
RUN wget http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-6-amd64.deb
RUN dpkg -i couchbase-release-1.0-6-amd64.deb
RUN apt-get update && \
  apt-get install -y  libcouchbase-dev libcouchbase2-libevent build-essential


WORKDIR /project_src

CMD ["/bin/sh"]
