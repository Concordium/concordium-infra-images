ARG ubuntu_version

FROM ubuntu:${ubuntu_version}

ARG RUST_VERSION
ARG GHC_VERSION
ARG STACK_VERSION
ARG PROTOC_VERSION

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

RUN curl https://sh.rustup.rs -sSf | sh -s -- --profile minimal --default-toolchain ${RUST_VERSION} -y; \
    # install fPIC GHC@$GHC_VERSION
    curl https://s3-eu-west-1.amazonaws.com/static-libraries.concordium.com/ghc-${GHC_VERSION}-fpic-gmp-x86_64-unknown-linux-gnu.tar.gz -o ghc.tar.gz; \
    tar -xf ghc.tar.gz; \
    cp -r bootstrapped_out/* /; \
    rm -r bootstrapped_out ghc.tar.gz;
    # install stack@$STACK_VERSION
RUN curl -L https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64.tar.gz -o stack.tar.gz; \
    tar -xf stack.tar.gz; \
    mkdir -p $HOME/.stack/bin;\
    mv stack-${STACK_VERSION}-linux-x86_64/stack $HOME/.stack/bin; \
    echo "system-ghc: true" > ~/.stack/config.yaml; \
    rm -rf stack.tar.gz; \
    stack update;
    # check
RUN cargo --version; \
    rustup --version; \
    rustc --version; \
    ghc --version; \
    stack --version;
