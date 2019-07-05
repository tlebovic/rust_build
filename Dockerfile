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
    apt-utils

# Static linking for C++ code
RUN sudo ln -s "/usr/bin/g++" "/usr/bin/musl-g++"

# install musl libc for static binaries 
RUN apt-get install -y musl musl-dev musl-tools


WORKDIR /project_src

CMD ["/bin/sh"]