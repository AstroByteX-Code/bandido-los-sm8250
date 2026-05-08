#!/bin/bash
#vanilla build script with concatenated defconfigs. I don't like it

ROOT_DIR="/home/me/kernelupgrade"
TC_DIR="$ROOT_DIR/toolchains/clang-22"
OUT_DIR="out"

export PATH="$TC_DIR/bin:$PATH"

export ARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KCFLAGS="-Wno-error=implicit-enum-enum-cast -Wno-error=int-conversion"

DEFCONFIGS="vendor/kona-perf_defconfig vendor/samsung/kona-sec-common.config vendor/samsung/r8q.config"

make O=$OUT_DIR $DEFCONFIGS
make O=$OUT_DIR olddefconfig

make -j$(nproc) O=$OUT_DIR Image.gz-dtb
