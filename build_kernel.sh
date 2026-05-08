#!/bin/bash
#complete Bandido kernel build script with LTO support
#the pgo support is unused right now

unset LLVM
#GCC SETUP
BUILD_CROSS_COMPILE=aarch64-linux-gnu-

#Enabling CLANG
export LLVM=1 LLVM_IAS=1

#setting toolchain path
ROOT_DIR="/home/me/kernelupgrade"
TC_DIR="$ROOT_DIR/toolchains/clang-22"
export PATH="$TC_DIR/bin:$PATH"

##########################################################
mkdir -p out
#rm out/dump*

export ARCH=arm64
CLANG_TRIPLE=aarch64-linux-gnu

CPU=$(($(nproc) - 1))
DATE_START=$(date +"%s")
IMAGE="out/arch/arm64/boot/Image.gz-dtb"

#Remove a previous kernel image
rm out/arch/arm64/boot/Image* &>/dev/null

make -j$CPU -C $(pwd) O=$(pwd)/out ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE CLANG_TRIPLE=$CLANG_TRIPLE bandido_defconfig

#Remove "=y" or "is not set"
scripts/configcleaner "CONFIG_LTO_CLANG
CONFIG_THINLTO
CONFIG_LTO_GCC
CONFIG_PGO_CLANG
CONFIG_PGOUSE_CLANG
"

if [[ -v LLVM ]]; then
	VERSION=$(${CLANG_DIR}clang -dumpversion | cut -d. -f1)
	COMPILER="clang$VERSION"
	echo -e "# CONFIG_LTO_GCC is not set\n" >>out/.config
	case $1 in
	lto)
		COMPILER="$COMPILER-lto"
		echo -e "\n################# Compiling FULL CLANG LTO build #################\n"
		echo -e "# CONFIG_THINLTO is not set\n" >>out/.config
		echo -e "# CONFIG_PGOUSE_CLANG is not set\n" >>out/.config
		echo -e "# CONFIG_PGO_CLANG is not set\n" >>out/.config
		echo -e "CONFIG_LTO_CLANG=y\n" >>out/.config
		;;
	pgo)
		echo -e "\n################# Compiling FULL CLANG LTO PGO build #################\n"
		echo -e "# CONFIG_THINLTO is not set\n" >>out/.config
		echo -e "CONFIG_PGO_CLANG=y\n" >>out/.config
		echo -e "# CONFIG_PGOUSE_CLANG is not set\n" >>out/.config
		echo -e "# CONFIG_LTO_CLANG is not set\n" >>out/.config
		;;
	pgouse)
		echo -e "\n################# Compiling FULL CLANG LTO PGOUSE build #################\n"
		echo -e "# CONFIG_THINLTO is not set\n" >>out/.config
		echo -e "# CONFIG_PGO_CLANG is not set\n" >>out/.config
		echo -e "CONFIG_PGOUSE_CLANG=y\n" >>out/.config
		;;
	*)
		echo -e "CONFIG_THINLTO=y\n" >>out/.config
		echo -e "# CONFIG_PGOUSE_CLANG is not set\n" >>out/.config
		echo -e "# CONFIG_PGO_CLANG is not set\n" >>out/.config
		echo -e "CONFIG_LTO_CLANG=y\n" >>out/.config
		;;
	esac
else
	VERSION=$(${BUILD_CROSS_COMPILE}gcc -dumpversion | cut -d. -f1)
	COMPILER="gcc$VERSION$2"
	case $1 in
	lto)
		COMPILER="$COMPILER-lto"
		echo -e "\n################# Compiling FULL GCC LTO build #################\n"
		echo -e "\nCONFIG_LTO_GCC=y\n" >>out/.config
		;;

	*)
		echo -e "\n# CONFIG_LTO_GCC is not set\n" >>out/.config
		;;
	esac
fi

make -j$CPU -C $(pwd) O=$(pwd)/out ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	CLANG_TRIPLE=$CLANG_TRIPLE oldconfig

make -j$CPU -C $(pwd) O=$(pwd)/out ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	CLANG_TRIPLE=$CLANG_TRIPLE Image.gz-dtb 2>&1 | tee compile-bandido.log

if [[ -f "$IMAGE" ]]; then
	DATE_END=$(date +"%s")
	DIFF=$(($DATE_END - $DATE_START))

	KERNELZIP="bandido-$COMPILER-$(date +"%Y%m%d%H%M").zip"

	rm AnyKernel3/dtb* >/dev/null 2>&1
	rm AnyKernel3/*Image* >/dev/null 2>&1
	rm AnyKernel3/*.zip >/dev/null 2>&1
	cp $IMAGE AnyKernel3/

	cd AnyKernel3

	zip -r9 $KERNELZIP . -x ".git/*" ".github/*" "README.md" "*placeholder" "modules/*"

	echo -e "\nTime elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.\n"

	#save a copy
	cp -v $KERNELZIP ~/build

	#this will wait for the device to try to flash automatically
	while true; do
		adb start-server >/dev/null 2>&1
		STATE=$(adb get-state 2>&1)

		if [[ $STATE == "device" ]]; then
			MODE=$(adb shell getprop sys.boot_completed 2>/dev/null)

			if [[ $MODE -eq 1 ]]; then
				echo -e "\a"
				echo "Device is connected but not in recovery mode."
				read -p "Press Enter to reboot to recovery mode..."
				adb reboot recovery
				echo "Rebooting to recovery mode..."
				REBOOT=1
			fi
		elif [[ $STATE == "recovery" ]]; then
			echo "Device is in recovery mode."
			break
		else
			echo "No devices or emulators found. Retrying in 5 seconds..."
			if [[ $REBOOT -ne 1 ]]; then
				echo -e "\a"
			fi
			sleep 5
		fi
	done

	adb push $KERNELZIP /sdcard/

	#is this right? hum
	adb shell "twrp install /sdcard/$KERNELZIP"
	adb shell sync
	sleep 2
	adb shell reboot
	echo -e "\a"
else
	echo -e "\nERROR. Something broke along the way since $IMAGE is not there\n"
fi
