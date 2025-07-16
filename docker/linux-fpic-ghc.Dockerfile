# BOOTSTRAP_GHC_VERSION corresponds to the version of GHC that we are using to build ghc.
ARG BOOTSTRAP_GHC_VERSION

FROM haskell:${BOOTSTRAP_GHC_VERSION}-bullseye

RUN apt-get update || \
        apt-get upgrade -y && \
        apt-get install -y libtool make m4 pkgconf autoconf automake curl libgmp-dev libncurses5-dev libtinfo6 build-essential python3

COPY scripts/linux-fpic-ghc.sh /linux-fpic-ghc.sh
RUN chmod +x /linux-fpic-ghc.sh
WORKDIR /
ENTRYPOINT ["./linux-fpic-ghc.sh"]
