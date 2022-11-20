#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

warn() { #helpmsg: Print a warning message
	echo >&2 ":: $*"
}

die() { #helpmsg: Print an error message and exit
	echo >&2
	echo >&2 "FATAL!"
	echo >&2 ":: $*"
	exit 1
}

quick_help() { #helpmsg: Print a short help
	grep -E '^.+{ #helpmsg' "$SCRIPT_DIR"/*.sh |
		grep -v '\^.' |
		grep -v 's|()' |
		sed -e 's|() { #helpmsg: |-|g' |
		column -s'-' -t |
		sort
}

check_commands() { #helpmsg: Test if a list of commands is available on the PATH
	local cmd
	for cmd in "$@"; do
		if ! [ -x "$(command -v "$cmd")" ]; then
			die "$cmd is not available!"
		fi
	done
}

update_license_copyright_year() { #helpmsg: Update copyright year in LICENSE file.
	YEAR="$(date '+%Y')"
	sed -i "s/Copyright [[:digit:]]\+/Copyright $YEAR/g" LICENSE
}

download() { #helpmsg: Download url (using curl) and verify the file (_download <md5> <url> [<archive>])
	check_commands curl md5sum
	local archive
	if [ -z "$3" ]; then
		archive="$(basename "$2")"
	else
		archive="$3"
	fi
	if [ ! -e "$TOOLS_FOLDER/$archive" ]; then
		mkdir -p "$TOOLS_FOLDER"
		cmd="curl -kSL $2 --progress-bar -o $TOOLS_FOLDER/${archive}.tmp"
		$cmd
		if [[ "$(md5sum "$TOOLS_FOLDER/${archive}.tmp" | cut -d' ' -f1)" != "$1" ]]; then
			die "Invalid md5sum for $archive: $(md5sum "TOOLS_FOLDER/${archive}.tmp")"
		fi
		mv "$TOOLS_FOLDER/${archive}.tmp" "$TOOLS_FOLDER/$archive"
	fi
}

install_zstd() {
	case "$OSTYPE" in
	msys)
		local result
		result=$(download_unpack 2109f0d91df9f98105ac993a62918400 https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-v1.5.2-win64.zip "ep" "" "")
		if [ ! -e "$TOOLS_FOLDER/bin/zstd" ]; then
			cp "$result/zstd" "$TOOLS_FOLDER/bin"
		fi
		;;
	linux*)
		install_debian_packages zstd
		;;
	*)
		die "Unsupported OS: $OSTYPE"
		;;
	esac
}

download_unpack() { #helpmsg: Download and unpack archive (_download_unpack <md5> <url> [<flags> <archive> <folder>])
	# flags: 'c' -> create_folder
	# flags: 'e' -> echo final folder
	# flags: 'p' -> add folder to PATH
	# flags: 'd' -> echo destination folder
	local archive
	local folder
	local extension
	local base_name
	local extension_bis
	local dst_folder
	local result
	if [ -z "$4" ]; then
		archive="$(basename "$2")"
	else
		archive="$4"
	fi
	download "$1" "$2" "$archive"
	if [ -z "$5" ]; then
		folder="${archive%.*}"
	else
		folder="$5"
	fi
	extension="${archive##*.}"
	base_name="${archive%.*}"
	extension_bis="${base_name##*.}"
	if [ "$extension_bis" == "tar" ]; then
		folder="${folder%.*}"
		extension="$extension_bis.$extension"
	fi
	if echo "$3" | grep -q 'c'; then
		dst_folder="$TOOLS_FOLDER/$folder"
	else
		dst_folder="$TOOLS_FOLDER"
	fi
	if [ ! -e "$dst_folder/.$archive" ]; then
		case "$extension" in
		"zip")
			unzip -q "$TOOLS_FOLDER/$archive" -d "$dst_folder" 2>/dev/null 1>/dev/null
			;;
		"tgz" | "tar.gz")
			mkdir -p "$dst_folder"
			tar -C "$dst_folder" -xzf "$TOOLS_FOLDER/$archive" 2>/dev/null 1>/dev/null
			;;
		"tar.xz")
			mkdir -p "$dst_folder"
			tar -C "$dst_folder" -xJf "$TOOLS_FOLDER/$archive" 2>/dev/null 1>/dev/null
			;;
		"tar.bz2")
			mkdir -p "$dst_folder"
			tar -C "$dst_folder" -xjf "$TOOLS_FOLDER/$archive" 2>/dev/null 1>/dev/null
			;;
		"tar.zst")
			install_zstd
			mkdir -p "$dst_folder"
			tar -C "$dst_folder" -I zstd -xf "$TOOLS_FOLDER/$archive" 2>/dev/null 1>/dev/null
			;;
		*)
			die "Unsupported file extension: $extension"
			;;
		esac
		touch "$dst_folder/.$archive"
	fi
	if echo "$3" | grep -q 'p'; then
		PATH="$dst_folder:$PATH"
	fi
	result="$TOOLS_FOLDER/$folder"
	if echo "$3" | grep -q 'e'; then
		echo "$result"
	fi
}

install_package() { #helpmsg: Install package
	case "$OSTYPE" in
	msys)
		md5_url="$(grep "^$1" <"$SCRIPT_DIR/msys_packages.txt")"
		md5="$(echo "$md5_url" | cut -d " " -f2)"
		url="$(echo "$md5_url" | cut -d " " -f3)"
		dependencies="$(echo "$md5_url" | cut -d " " -f4-)"
		download_unpack "$md5" "$url" "e" "" ""
		if [ -n "$dependencies" ]; then
			# shellcheck disable=SC2086
			install_packages $dependencies
		fi
		;;
	linux*)
		install_debian_packages "$1"
		;;
	*)
		die "Unsupported OS: $OSTYPE"
		;;
	esac
}

install_packages() { #helpmsg: Install multiple packages
	for package in "$@"; do
		install_package "$package"
	done
}
