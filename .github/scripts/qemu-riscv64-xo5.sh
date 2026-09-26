#!/usr/bin/env bash
# Runs inside a linux/riscv64 container under QEMU user-mode, on an x86 runner.
# Builds xo-web (XO 5) with riscv64 Node. Native riscv64 hardware (BPI-F3, RISE
# EM-RV1) crashes V8 in gulp buildScripts; this job checks the same build under
# emulation. Usage: bash .github/scripts/qemu-riscv64-xo5.sh
set -euo pipefail
NODE_VERSION=v22.23.2
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq --no-install-recommends ca-certificates curl xz-utils git \
  python3 make g++ pkg-config libfuse-dev time >/dev/null

base=https://unofficial-builds.nodejs.org/download/release/$NODE_VERSION
tarball=node-$NODE_VERSION-linux-riscv64.tar.xz
curl -fsSLO "$base/$tarball"
curl -fsSL "$base/SHASUMS256.txt" | grep " $tarball\$" | sha256sum -c -
mkdir -p /opt/node && tar -xJf "$tarball" -C /opt/node --strip-components=1
export PATH=/opt/node/bin:$PATH
corepack enable
corepack prepare yarn@1.22.22 --activate
git config --global --add safe.directory '*'

uname -m
node -p "[process.platform, process.arch, process.version, process.versions.v8].join(' ')"
grep -m1 '^isa' /proc/cpuinfo || true

# leveldb 1.20 (bundled by leveldown) has no AtomicPointer for riscv64
CXXFLAGS=-DLEVELDB_ATOMIC_PRESENT /usr/bin/time -v yarn 2>&1 | tee install.log
/usr/bin/time -v node .github/scripts/build-deps.mjs xo-web 2>&1 | tee xo5-build.log
grep '^BUILD' xo5-build.log
test -s packages/xo-web/dist/index.js
ls -l packages/xo-web/dist/index.js
