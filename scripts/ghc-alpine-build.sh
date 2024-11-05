#!/bin/sh

set -ex

. "$HOME/.ghcup/env"

cd ghc/
cabal install happy alex --install-method=copy
cp ~/.cabal/bin/* /usr/bin

# Build GHC
./boot
./configure --disable-numa
./hadrian/build -j17 --docs=none
mkdir _build/docs
./hadrian/build binary-dist --docs=none

# Copy ghc to out
ls _build
ls _build/bindist
cp _build/bindist/ghc-"$GHC_VERSION"-x86_64-unknown-linux.tar.xz /build/pkg-root/ghc-"$GHC_VERSION"-x86_64-unknown-linux-integer-gmp.tar.xz
