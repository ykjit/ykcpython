#! /bin/sh

set -e

# Install rustup.
export CARGO_HOME="`pwd`/.cargo"
export RUSTUP_HOME="`pwd`/.rustup"
export RUSTUP_INIT_SKIP_PATH_CHECK="yes"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
sh rustup.sh --default-host x86_64-unknown-linux-gnu \
    --default-toolchain nightly \
    --no-modify-path \
    --profile minimal \
    -y
export PATH=${CARGO_HOME}/bin/:$PATH

git clone -b yk/12.0-2021-04-15 https://github.com/vext01/llvm-project
cd llvm-project
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=`pwd`/../inst \
    -DLLVM_INSTALL_UTILS=On \
    -DCMAKE_BUILD_TYPE=release \
    -DLLVM_ENABLE_ASSERTIONS=On \
    -DLLVM_ENABLE_PROJECTS="lld;clang" \
    ../llvm
make -j `nproc` install
export PATH=`pwd`/../inst/bin:${PATH}
cd ../..

git clone https://github.com/softdevteam/yk/
cd yk && cargo build --release
YK_INST_DIR=`pwd`/target/release/
cd ..

# We only add --enable-shared to stop a test that removes LD_LIBRARY_PATH from
# its env before trying to run the just-build python executable.
LDFLAGS=-L`pwd`/yk/target/release CC=clang \
  CPPFLAGS=-I`pwd`/yk/ykcapi \
  CFLAGS="-Wno-unused-value -Wno-empty-body -Qunused-arguments" \
  ./configure --enable-shared

LDFLAGS=-L`pwd`/yk/target/release \
  CC=clang \
  CPPFLAGS=-I`pwd`/yk/ykcapi \
  CFLAGS="-Wno-unused-value -Wno-empty-body -Qunused-arguments" \
  LD_LIBRARY_PATH=`pwd`/yk/target/release \
  make -j `nproc` test
