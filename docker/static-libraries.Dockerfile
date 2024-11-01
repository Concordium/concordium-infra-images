ARG ubuntu_version

FROM ubuntu:${ubuntu_version}

ARG rust_version
ARG ghc_version
ARG stack_version
ARG protoc_version

ENV RUST_VERSION=$rust_version
ENV GHC_VERSION=$ghc_version
ENV STACK_VERSION=$stack_version
ENV PROTOC_VERSION=$protoc_version

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/root/.cargo/bin:/root/.stack/bin"

RUN set -eux && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        curl \
        git \
        g++ \
        liblmdb-dev \
        libpq-dev \
        libgmp-dev \
        libz-dev \
        libssl-dev \
        make \
        pkgconf \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Install protoc by version specified in environment.
RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -o protoc.zip; \
    unzip protoc.zip bin/protoc -d /usr/; \
    rm protoc.zip

RUN curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain ${rust_version} -y; \
    # install fPIC GHC@$ghc_version
    curl https://s3-eu-west-1.amazonaws.com/static-libraries.concordium.com/ghc-${ghc_version}-fpic-gmp-x86_64-unknown-linux-gnu.tar.gz -o ghc.tar.gz; \
    tar -xf ghc.tar.gz; \
    cp -r bootstrapped_out/* /; \
    rm -r bootstrapped_out ghc.tar.gz; \
    # install stack@$stack_version
    curl -L https://github.com/commercialhaskell/stack/releases/download/v${stack_version}/stack-${stack_version}-linux-x86_64.tar.gz -o stack.tar.gz; \
    tar -xf stack.tar.gz; \
    mkdir -p $HOME/.stack/bin;\
    mv stack-${stack_version}-linux-x86_64/stack $HOME/.stack/bin; \
    echo "system-ghc: true" > ~/.stack/config.yaml; \
    rm -rf stack.tar.gz; \
    stack update; \
    # check
    cargo --version; \
    rustup --version; \
    rustc --version; \
    ghc --version; \
    stack --version;
