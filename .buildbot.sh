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

git clone https://github.com/ykjit/ykllvm
cd ykllvm
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
cd yk && cargo build
YK_INST_DIR=`pwd`/target/debug/
cd ..

# The CFLAGS are those suggest for clang in
# https://devguide.python.org/setup/#clang.
LDFLAGS="-L$YK_INST_DIR -Wl,-rpath=$YK_INST_DIR" CC=clang \
  CPPFLAGS=-I`pwd`/yk/ykcapi \
  CFLAGS="-Wno-unused-value -Wno-empty-body -Qunused-arguments" \
  ./configure

LDFLAGS="-L$YK_INST_DIR -Wl,-rpath=$YK_INST_DIR" \
  CC=clang \
  CPPFLAGS=-I`pwd`/yk/ykcapi \
  CFLAGS="-Wno-unused-value -Wno-empty-body -Qunused-arguments" \
  LD_LIBRARY_PATH=`pwd`/yk/target/release \
  make -j `nproc` test
