#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

setup_virtual_env() { #helpmsg: Setup a virtual environment in current folder (in subfolder venv)
	# Where to find the binaries
	if [ -f /.dockerenv ] || grep -q 'docker\|lxc' /proc/1/cgroup; then
		VENV_FOLDER="venv-docker"
	else
		VENV_FOLDER="venv"
	fi
	if [ "$OSTYPE" != "msys" ]; then
		VENV="$(pwd)/$VENV_FOLDER/bin"
	else
		VENV="$(pwd)/$VENV_FOLDER/Scripts"
	fi
	if [ "$OSTYPE" != "msys" ]; then
		install_debian_packages libffi-dev libssl-dev
	fi
	# Setup VENV
	if [ ! -e "$(pwd)/$VENV_FOLDER" ]; then
		if [ -z ${PYTHON3+x} ]; then
			PYTHON3=/usr/bin/python3
		fi
		install_debian_packages python3-venv python3-pip python3-setuptools python3-wheel
		"$PYTHON3" -m venv "$(pwd)/$VENV_FOLDER"
		"$VENV/python" -m pip install --upgrade pip
		"$VENV/python" -m pip install setuptools wheel
	fi
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		if [ ! -e "$(pwd)/$VENV_FOLDER/$1.installed" ]; then
			"$VENV/python" -m pip install -r "$(pwd)/requirements_$1.txt"
			touch "$(pwd)/$VENV_FOLDER/$1.installed"
		fi
	fi
	if [ -e "$(pwd)/requirements.txt" ]; then
		PRJ="$(basename "$(dirname "$(realpath "$0")")")"
		if [ ! -e "$(pwd)/$VENV_FOLDER/${PRJ}.installed" ]; then
			"$VENV/python" -m pip install -r "$(pwd)/requirements.txt"
			touch "$(pwd)/$VENV_FOLDER/${PRJ}.installed"
		fi
	fi
	PATH="$VENV:$PATH"
}
