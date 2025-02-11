# GHC custom build

Due to the way we build the project and because we cannot specify to Rustc that it should use `--no-pie`
only in certain artifacts ([see](https://github.com/rust-lang/cargo/issues/5115)), we need our libraries to be `fPIC`.

This particularly means that Haskell libraries, the Haskell RTS and libCffi must be compiled with `-fPIC`.

To make fully static builds we also need to remove the `integer-gmp` dependency due to licensing issues.
For those need to use the `integer-simple` variant, as opposed to the default `integer-gmp` one.

The bindist for vanilla debian ghc is installed to then bootstrap our own ghc build. The output is a GHC instalation inside a tar file
that can be unpacked and used.
