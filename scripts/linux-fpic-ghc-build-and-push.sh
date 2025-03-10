#!/usr/bin/env bash

set -e

if [ -z "$GHC_VERSION" ]; then
    echo "GHC_VERSION not set"
    exit 1
fi

if [ -z "$INTEGER_VARIANT" ]; then
    echo "INTEGER_VARIANT not set"
    exit 1
fi

# GHC_VERSION corresponds to the version of GHC that we are building.
# BOOTSTRAP_GHC_VERSION corresponds to the version of GHC that we are using to build GHC_VERSION.
docker build -t concordium/fpic-ghc:"${GHC_VERSION}" -f docker/linux-fpic-ghc.Dockerfile --build-arg BOOTSTRAP_GHC_VERSION="$BOOTSTRAP_GHC_VERSION" .
mkdir out
docker run --name fpic-ghc -e GHC_VERSION -v "$(pwd)/out":/out concordium/fpic-ghc:"${GHC_VERSION}"
aws s3 cp out/ghc-"$GHC_VERSION"-fpic-"$INTEGER_VARIANT"-x86_64-unknown-linux-gnu.tar.gz s3://static-libraries.concordium.com/ --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
