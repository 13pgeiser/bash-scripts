#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git
install_gcc_arm_none_eabi() { #helpmsg: Install gcc for arm target.
	case "$OSTYPE" in
	msys)
		local result
		result=$(download_unpack 82525522fefbde0b7811263ee8172b10 https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-win32.zip.bz2 "ce" "gcc-arm-none-eabi-9-2019-q4-major-win32.zip" "")
		path_add "$result/bin"
		;;
	linux*)
		local result
		result=$(download_unpack fe0029de4f4ec43cf7008944e34ff8cc https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2 "ce" "" "")
		path_add "$result/gcc-arm-none-eabi-9-2019-q4-major/bin"
		;;
	*)
		die "Unsupported OS: $OSTYPE"
		;;
	esac
	if [ -x "$(command -v "cmake")" ]; then
		cat <<EOF >arm-none-eabi.cmake
# Automatically created by the configure script
# DO NOT EDIT MANUALLY!
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP arm-none-eabi-objdump)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
	fi
}

write_sourceme() { #helpmsg: Write a "sourceme" file with some alias and the actual PATH.
	cat <<EOF >sourceme
#!/bin/bash
alias g="gitk --all &"
EOF
	echo "PATH=\"$PATH\"" >>"$PWD/sourceme"
	# shellcheck disable=SC1091
	source "$PWD/sourceme"
}

install_cmake() { #helpmsg: Install cmake
	case "$OSTYPE" in
	msys)
		local result
		result=$(download_unpack 1eea56fc6999da745caa86bac06279ee https://github.com/Kitware/CMake/releases/download/v3.25.0/cmake-3.25.0-windows-x86_64.zip "e" "" "")
		path_add "$result/bin"
		;;
	linux*)
		install_debian_packages cmake
		;;
	*)
		die "Unsupported OS: $OSTYPE"
		;;
	esac
}

call_cmake() { #helpmsg: Correctly call cmake both on Linux and Msys2
	rm -rf CMakeFiles/
	rm -f CMakeCache.txt cmake_install.cmake compile_commands.json Makefile
	case "$OSTYPE" in
	msys)
		cmake -G "MSYS Makefiles" . "$@"
		;;
	linux*)
		cmake . "$@"
		;;
	*)
		die "Unsupported OS: $OSTYPE"
		;;
	esac
}

git_clone() { #helpmsg: Clone repo if does not exists yet
	# 1 : folder
	# 2 : url
	# 3 : branch or tag
	if [ ! -d "$1" ]; then
		git clone "$2" "$1"
		(
			cd "$1" || exit 1
			git checkout "$3" -b "$(basename "$3")"
		)
	fi
}

apply_patches() { #helpmsg: Clone repo if does not exists yet
	# 1 : folder
	# 2 : patch folder
	if [ ! -e "$1/.patched" ]; then
		(
			cd "$1" || exit 1
			for patch in "$2"/*.patch; do
				patch -p1 <"$patch"
			done
		)
		touch "$1/.patched"
	fi
}
