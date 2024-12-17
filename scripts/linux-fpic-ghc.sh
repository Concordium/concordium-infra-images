#!/bin/bash -e

# $GHC_VERSION must be set
[ -z "$GHC_VERSION" ] && exit 1

# If the integer library is set use it, otherwise default to gmp (the GHC default)
# The options for the value are gmp and simple for GHC<9.6, and gmp, native, check-gmp, and ffi
# for later versions.
INTEGER_VARIANT="${GHC_INTEGER_VARIANT:-gmp}"

# Download GHC source
SOURCE="ghc-$GHC_VERSION-src.tar.xz"
curl https://downloads.haskell.org/~ghc/"$GHC_VERSION"/"$SOURCE" -o "$SOURCE"
tar xf "$SOURCE"
rm "$SOURCE"

# Configure the build
#
# This sets the PIC option for all core Haskell libraries (GhcLibHcOpts)
# the runtime library (GhcRtsHcOpts), as well as for the libffi library bundled with GHC (the SRC_CC_OPTS).
#
# In turn having core libraries be position independent allows that the Haskell
# projects built with this compiler are linked into static binaries. It also
# allows us to produce profiling enabled versions of Haskell packages.
(
    cd ghc-"$GHC_VERSION"

    if [ -f Makefile ]; then
        cat <<'EOF' >mk/build.mk
V=0

GhcLibHcOpts += -fPIC
GhcRtsHcOpts += -fPIC
SRC_CC_OPTS += -fPIC
STRIP_CMD = :

BUILD_SPHINX_PDF=NO
WITH_TERMINFO=NO
EOF

        # And select the integer library that GHC will have enabled.
        echo "INTEGER_LIBRARY = integer-${INTEGER_VARIANT}" >>mk/build.mk

        ./configure --disable-numa
        make -j8
        mkdir /bootstrapped_out
        make DESTDIR=/bootstrapped_out install
    else
        # Use hadrian to build.

        ./configure --disable-numa
        cabal update

        mkdir -p _build
        cat <<'EOF' >_build/hadrian.settings
stage1.*.ghc.*.opts += -fPIC
stage1.*.cc.*.opts += -fPIC
EOF
        ./hadrian/build --bignum=${INTEGER_VARIANT} --flavour=perf --docs=none -j8 binary-dist-dir

        (
            cd _build/bindist/ghc-"$GHC_VERSION"-x86_64-unknown-linux
            ./configure --prefix /usr/local
            mkdir /boostrapped_out
            make DESTDIR=/bootstrapped_out install
        )
    fi
)

# Package the ghc installation. This packages the entire directory structure
# that should just be unpacked in / to be used.
tar czvf /out/ghc-"$GHC_VERSION"-fpic-"$INTEGER_VARIANT"-x86_64-unknown-linux-gnu.tar.gz /bootstrapped_out
