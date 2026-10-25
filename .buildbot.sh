#! /bin/sh

set -e

./configure
make -j "$(nproc)"
make test TESTOPTS="-j $(nproc)"
