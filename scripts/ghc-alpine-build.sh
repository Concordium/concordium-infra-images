#!/usr/bin/env bash

set -ex

docker build -t concordium/alpine-ghc -f docker/ghc-alpine.Dockerfile --build-arg BOOTSTRAP_HASKELL_GHC_VERSION="$BOOTSTRAP_HASKELL_GHC_VERSION" --build-arg GHC_VERSION="$GHC_VERSION" .
mkdir out
docker run --name alpine-ghc -e GHC_VERSION -v "$(pwd)"/out:/out concordium/alpine-ghc
aws s3 cp out/ghc-"$GHC_VERSION"-x86_64-unknown-linux-integer-gmp.tar.xz s3://static-libraries.concordium.com/ --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
