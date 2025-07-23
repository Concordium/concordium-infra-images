ARG GHC_VERSION=9.10.2

# FROM haskell:${GHC_VERSION}

### BEGIN WORKAROUND ###
# Since currently there is no haskell image with GHC 9.10.2, we use debian bookworm as base image.
# This is a workaround until the haskell image is updated. This is based on how the haskell image
# is built. (See: https://github.com/haskell/docker-haskell/blob/master/9.10/bullseye/Dockerfile)
# Note that bookworm supports postgresql 15, whereas bullseye supports version 13, which is too
# old for the LTS-24.0 dependencies (required by the wallet-proxy).

FROM debian:bookworm


ENV LANG=C.UTF-8

# common haskell + stack dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dpkg-dev \
        git \
        gcc \
        gnupg \
        g++ \
        libc6-dev \
        libffi-dev \
        libgmp-dev \
        libnuma-dev \
        libtinfo-dev \
        make \
        netbase \
        xz-utils \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

ARG STACK=3.7.1
ARG STACK_RELEASE_KEY=C5705533DA4F78D8664B5DC0575159689BEFB442

RUN set -eux; \
    cd /tmp; \
    ARCH="$(dpkg-architecture --query DEB_BUILD_GNU_CPU)"; \
    STACK_URL="https://github.com/commercialhaskell/stack/releases/download/v${STACK}/stack-${STACK}-linux-$ARCH.tar.gz"; \
    # sha256 from https://github.com/commercialhaskell/stack/releases/download/v${STACK}/stack-${STACK}-linux-$ARCH.tar.gz.sha256
    case "$ARCH" in \
        'aarch64') \
            STACK_SHA256='752321c6af6bc88960a086ebd9ede72937a567f312842a29deb2ddc9ab316a20'; \
            ;; \
        'x86_64') \
            STACK_SHA256='b6df9168d471d917d955ee80553562ca2b0b3b1aa61cd1256199406c2d8c4eb4'; \
            ;; \
        *) echo >&2 "error: unsupported architecture '$ARCH'" ; exit 1 ;; \
    esac; \
    curl -sSL "$STACK_URL" -o stack.tar.gz; \
    echo "$STACK_SHA256 stack.tar.gz" | sha256sum --strict --check; \
    \
    curl -sSL "$STACK_URL.asc" -o stack.tar.gz.asc; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    gpg --batch --keyserver keyserver.ubuntu.com --receive-keys "$STACK_RELEASE_KEY"; \
    gpg --batch --verify stack.tar.gz.asc stack.tar.gz; \
    gpgconf --kill all; \
    \
    tar -xf stack.tar.gz -C /usr/local/bin --strip-components=1 "stack-$STACK-linux-$ARCH/stack"; \
    stack config set system-ghc --global true; \
    stack config set install-ghc --global false; \
    \
    rm -rf /tmp/*; \
    \
    stack --version;

ARG CABAL_INSTALL=3.12.1.0
ARG CABAL_INSTALL_RELEASE_KEY=1E07C9A1A3088BAD47F74A3E227EE1942B0BDB95

RUN set -eux; \
    cd /tmp; \
    ARCH="$(dpkg-architecture --query DEB_BUILD_GNU_CPU)"; \
    CABAL_INSTALL_TAR="cabal-install-$CABAL_INSTALL-$ARCH-linux-deb11.tar.xz"; \
    CABAL_INSTALL_URL="https://downloads.haskell.org/~cabal/cabal-install-$CABAL_INSTALL/$CABAL_INSTALL_TAR"; \
    CABAL_INSTALL_SHA256SUMS_URL="https://downloads.haskell.org/~cabal/cabal-install-$CABAL_INSTALL/SHA256SUMS"; \
    # sha256 from https://downloads.haskell.org/~cabal/cabal-install-$CABAL_INSTALL/SHA256SUMS
    case "$ARCH" in \
        'aarch64') \
            CABAL_INSTALL_SHA256='c14e8198407f37f7276c77b5cefef60ee6a929b4c22d7316577ce8e2301a758e'; \
            ;; \
        'x86_64') \
            CABAL_INSTALL_SHA256='4f60cf1c72f4ad4d82d668839ac61ae15ae4faf6c4b809395799e8a3ee622051'; \
            ;; \
        *) echo >&2 "error: unsupported architecture '$ARCH'"; exit 1 ;; \
    esac; \
    curl -fSL "$CABAL_INSTALL_URL" -o cabal-install.tar.gz; \
    echo "$CABAL_INSTALL_SHA256 cabal-install.tar.gz" | sha256sum --strict --check; \
    \
    curl -sSLO "$CABAL_INSTALL_SHA256SUMS_URL"; \
    curl -sSLO "$CABAL_INSTALL_SHA256SUMS_URL.sig"; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    gpg --batch --keyserver keyserver.ubuntu.com --receive-keys "$CABAL_INSTALL_RELEASE_KEY"; \
    gpg --batch --verify SHA256SUMS.sig SHA256SUMS; \
    # confirm we are verifying SHA256SUMS that matches the release + sha256
    grep "$CABAL_INSTALL_SHA256  $CABAL_INSTALL_TAR" SHA256SUMS; \
    gpgconf --kill all; \
    \
    tar -xf cabal-install.tar.gz -C /usr/local/bin; \
    \
    rm -rf /tmp/*; \
    \
    cabal --version

ARG GHC=9.10.2
ARG GHC_RELEASE_KEY=88B57FCF7DB53B4DB3BFA4B1588764FBE22D19C4

RUN set -eux; \
    cd /tmp; \
    ARCH="$(dpkg-architecture --query DEB_BUILD_GNU_CPU)"; \
    GHC_URL="https://downloads.haskell.org/~ghc/$GHC/ghc-$GHC-$ARCH-deb11-linux.tar.xz"; \
    # sha256 from https://downloads.haskell.org/~ghc/$GHC/SHA256SUMS
    case "$ARCH" in \
        'aarch64') \
            GHC_SHA256='0188ca098abdaf71eb0804d0f35311f405da489137d8d438bfaa43b8d1e3f1b0'; \
            ;; \
        'x86_64') \
            GHC_SHA256='2fe2c3e0a07e4782530e8bf83eeda8ff6935e40d5450c1809abcdc6182c9c848'; \
            ;; \
        *) echo >&2 "error: unsupported architecture '$ARCH'" ; exit 1 ;; \
    esac; \
    curl -sSL "$GHC_URL" -o ghc.tar.xz; \
    echo "$GHC_SHA256 ghc.tar.xz" | sha256sum --strict --check; \
    \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    curl -sSL "$GHC_URL.sig" -o ghc.tar.xz.sig; \
    gpg --batch --keyserver keyserver.ubuntu.com --receive-keys "$GHC_RELEASE_KEY"; \
    gpg --batch --verify ghc.tar.xz.sig ghc.tar.xz; \
    gpgconf --kill all; \
    \
    tar xf ghc.tar.xz; \
    cd "ghc-$GHC-$ARCH-unknown-linux"; \
    ./configure --prefix "/opt/ghc/$GHC"; \
    make install; \
    \
    rm -rf /tmp/*; \
    \
    "/opt/ghc/$GHC/bin/ghc" --version

ENV PATH=/root/.cabal/bin:/root/.local/bin:/opt/ghc/${GHC}/bin:$PATH

### END WORKAROUND ###

ARG FLATBUFFERS_TAG
ARG RUST_VERSION
ARG PROTOC_VERSION
ARG NVM_SH_VERSION
ARG CMAKE_VERSION



ENV LANG=C.UTF-8

RUN apt-get update && \
apt-get install -y --no-install-recommends gnupg ca-certificates dirmngr musl-tools unzip && \
rm -rf /var/lib/apt/lists/*

ENV PROTOC_VERSION=${PROTOC_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/root/.cargo/bin"
ENV NVM_DIR="/root/.nvm"

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        curl \
        git \
        clang \
        g++ \
        liblmdb-dev \
        libpq-dev \
        libz-dev \
        libssl-dev \
        pkgconf \
        libunbound-dev \
    && rm -rf /var/lib/apt/lists/*

# Install protoc by version specified in environment.
RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o protoc.zip && \
    unzip protoc.zip bin/protoc -d /usr/ && \
    rm protoc.zip

# Install CMAKE version 3.25 and extract it to /usr/local
RUN curl -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz --output cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz && \
    gzip -dc cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz | tar xf cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz -C /usr/local --strip-components=1

# Install rust.
RUN curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain "$RUST_VERSION" --component clippy -y

# Install wabt.
RUN git clone --branch 1.0.19 --depth 1 --recurse-submodules https://github.com/WebAssembly/wabt.git && \
    ( cd wabt && make install ) && \
    rm -rf wabt

# Install flatbuffers. Must be kept in sync with 'distribution/node/deb/docker/build.sh'
RUN git clone --branch "$FLATBUFFERS_TAG" --depth 1 https://github.com/google/flatbuffers.git && \
    ( cd flatbuffers && cmake -G "Unix Makefiles" . && make -j"$(nproc)" && make install ) && \
    rm -rf flatbuffers

# Update stack.
RUN stack update

# Install nvm and node.
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_SH_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install node

# Debugging info.
RUN node --version; \
    rustc --version; \
    cargo --version; \
    ghc --version; \
    stack --version; \
    cargo clippy -- --version
