#!/bin/bash
set -e  

SECONDS=0
KERNEL_DIR=$(pwd)
DEVICE="$1"
TOOLCHAIN_DIR="$2"
OUT_DIR="out/$DEVICE"
AK3_DIR="$KERNEL_DIR/AnyKernel3"
TC_DIR="$KERNEL_DIR/toolchains/llvm-23.1.0-rc3-x86_64"

# ===== Colors =====
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ===== Environment =====
export PATH="$TC_DIR/bin:$PATH"
export CC="ccache clang"
export ARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export PLATFORM_VERSION=11
export KCFLAGS="-Wno-error=pointer-to-enum-cast -Wno-error=int-conversion -Wno-unused-variable -Wno-unused-function"

# ===== Clean build =====
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

DEFCONFIG="vendor/kona-sec-perf_defconfig \
           vendor/samsung/${DEVICE}.config \
           vendor/bandido/ksu.config \
           vendor/bandido/localversion.config"

echo -e "${YELLOW}Building with defconfigs: $DEFCONFIG${NC}"
make O="$OUT_DIR" ARCH=arm64 $DEFCONFIG
make O="$OUT_DIR" ARCH=arm64 olddefconfig

echo -e "\n${YELLOW}Starting compilation...${NC}\n"
make -j$(nproc) O="$OUT_DIR" Image.gz-dtb
make -j$(nproc) O="$OUT_DIR" dtbs

# ===== Verify Image =====
if [ -f "$OUT_DIR/arch/arm64/boot/Image.gz-dtb" ]; then
    echo -e "${GREEN}Kernel Image.gz-dtb found!${NC}"
else
    echo -e "${RED}Compilation failed! Image.gz-dtb not found.${NC}"
    exit 1
fi

# ===== Handle DTBs =====
DTB_FILES=$(find "$OUT_DIR/arch/arm64/boot/dts" -name "*.dtb" | sort)
if [ -n "$DTB_FILES" ]; then
    echo -e "${BLUE}Concatenating DTBs...${NC}"
    cat $DTB_FILES > "$OUT_DIR/dtb"
    echo -e "${GREEN}dtb generated successfully!${NC}"
else
    echo -e "${YELLOW}No DTB files found, skipping dtb concatenation.${NC}"
fi

# ===== Handle DTBO =====
DTBO_FILES=$(find "$OUT_DIR/arch/arm64/boot/dts/samsung/$DEVICE" -name "*.dtbo")
if [ -n "$DTBO_FILES" ]; then
    echo -e "${BLUE}Building dtbo.img...${NC}"
    "$KERNEL_DIR/tools/mkdtimg" create "$OUT_DIR/dtbo.img" --page_size=4096 ${DTBO_FILES}
    echo -e "${GREEN}dtbo.img created successfully!${NC}"
else
    echo -e "${YELLOW}No DTBO files found for $DEVICE.${NC}"
fi

# ===== Package with AnyKernel3 =====
[ ! -d "$AK3_DIR" ] && echo -e "${RED}AnyKernel3 directory not found!${NC}" && exit 1

echo -e "📦 Packaging AnyKernel3 zip for $DEVICE"
cd "$AK3_DIR" || exit 1
rm -f Image.gz-dtb dtb dtbo.img

cp "$KERNEL_DIR/$OUT_DIR/arch/arm64/boot/Image.gz-dtb" Image.gz-dtb
[ -f "$KERNEL_DIR/$OUT_DIR/dtb" ] && cp "$KERNEL_DIR/$OUT_DIR/dtb" dtb
[ -f "$KERNEL_DIR/$OUT_DIR/dtbo.img" ] && cp "$KERNEL_DIR/$OUT_DIR/dtbo.img" dtbo.img

sed -i "s/^device\.name1=.*/device.name1=${DEVICE}/" anykernel.sh

BUILD_DATE=$(date +"%Y-%m-%d_%H-%M")
ZIP_NAME="Bandido-kernel-${DEVICE}-${BUILD_DATE}.zip"
zip -r "../${ZIP_NAME}" * -x "*.git*" "README.md" "*placeholder"

cd "$KERNEL_DIR"
echo -e "\n${GREEN}Completed in $((SECONDS / 60))m $((SECONDS % 60))s${NC}"
echo -e "${GREEN}Output zip: $ZIP_NAME${NC}"
