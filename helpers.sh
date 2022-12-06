#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

LANG=en_US.UTF_8

# Current script folder
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Set USER when running on msys.
if [ "$OSTYPE" == "msys" ]; then
	export USER="$USERNAME"
fi

# Gitlab-CI does not set the USER variable.
if [ -z ${USER+x} ]; then
	USER="unknown"
fi

# Set TOOLS_FOLDER variable.
if [ -z ${TOOLS_FOLDER+x} ]; then
	TOOLS_FOLDER=$(realpath _tools)
	export TOOLS_FOLDER
fi

# Update PATH
path_add() {
	in_path="$(echo "$PATH" | tr ":" "\n" | grep "^$1" || true)"
	if [ -z "$in_path" ]; then
		PATH="$1:$PATH"
	fi
}

path_add "$TOOLS_FOLDER/mingw64/bin"
path_add "$TOOLS_FOLDER/usr/bin"
path_add "$TOOLS_FOLDER/bin"

echo "********************************************************************************"
echo "* OSTYPE:        $OSTYPE"
echo "* HOSTTYPE:      $HOSTTYPE"
echo "* USER:          $USER"
echo "* SCRIPT_DIR:    $SCRIPT_DIR"
echo "* TOOLS_FOLDER:  $TOOLS_FOLDER"
echo "********************************************************************************"

# Source helpers.
# shellcheck source=helpers_base.sh
source "$SCRIPT_DIR/helpers_base.sh"
# shellcheck source=helpers_cpp.sh
source "$SCRIPT_DIR/helpers_cpp.sh"
# shellcheck source=helpers_debian.sh
source "$SCRIPT_DIR/helpers_debian.sh"
# shellcheck source=helpers_docker.sh
source "$SCRIPT_DIR/helpers_docker.sh"
# shellcheck source=helpers_python.sh
source "$SCRIPT_DIR/helpers_python.sh"
# shellcheck source=helpers_qemu.sh
source "$SCRIPT_DIR/helpers_qemu.sh"

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
	echo "This script is designed to be sourced!"
	echo
	quick_help ""
	die "Please source me!"
fi
