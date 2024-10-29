ARG ghc_version

FROM haskell:${ghc_version}-buster

ARG flatbuffers_tag
ARG rust_version
ARG protoc_version
ARG nvm_sh_version
ARG cmake_version

ENV PROTOC_VERSION=${protoc_version}

ENV LANG C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg ca-certificates dirmngr musl-tools && \
    rm -rf /var/lib/apt/lists/*

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
RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o protoc.zip; \
    unzip protoc.zip bin/protoc -d /usr/; \
    rm protoc.zip

# Install CMAKE version 3.25 and extract it to /usr/local
RUN curl -L https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-{cmake_version}-linux-x86_64.tar.gz --output cmake-3.25.1-linux-x86_64.tar.gz && \
    tar xf cmake-${cmake_version}-linux-x86_64.tar.gz -C /usr/local --strip-components=1

# Install rust.
RUN curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain "$rust_version" --component clippy -y

# Install wabt.
RUN git clone --branch 1.0.19 --depth 1 --recurse-submodules https://github.com/WebAssembly/wabt.git && \
    ( cd wabt && make install ) && \
    rm -rf wabt

# Install flatbuffers. Must be kept in sync with 'distribution/node/deb/docker/build.sh'
RUN git clone --branch "$flatbuffers_tag" --depth 1 https://github.com/google/flatbuffers.git && \
    ( cd flatbuffers && cmake -G "Unix Makefiles" . && make -j"$(nproc)" && make install ) && \
    rm -rf flatbuffers

# Update stack.
RUN stack update

# Install nvm and node.
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_sh_version}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install node

# Debugging info.
RUN node --version; \
    rustc --version; \
    cargo --version; \
    ghc --version; \
    stack --version; \
    cargo clippy -- --version
