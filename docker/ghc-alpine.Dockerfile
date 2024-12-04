FROM alpine:latest
ARG GHC_VERSION
ARG BOOTSTRAP_HASKELL_GHC_VERSION

WORKDIR /

# Install system ghc and dependencies
RUN apk add musl-dev python3 autoconf automake ncurses-dev make file g++ xz git bash wget gmp-dev gmp libffi libffi-dev curl
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_NO_UPGRADE=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Get GHC source
RUN git clone -b ghc-"$GHC_VERSION"-release https://gitlab.haskell.org/ghc/ghc.git/ --recurse-submodules

COPY alpine-integer-gmp-ghc.sh /alpine-integer-gmp-ghc.sh
RUN chmod +x /alpine-integer-gmp-ghc.sh
ENTRYPOINT ["./alpine-integer-gmp-ghc.sh"]
