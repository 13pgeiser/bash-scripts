#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

setup_virtual_env() { #helpmsg: Setup a virtual environment in current folder (in subfolder venv)
	# Where to find the binaries
	if [ "$OSTYPE" != "msys" ]; then
		VENV="$(pwd)/venv/bin"
	else
		VENV="$(pwd)/venv/Scripts"
	fi
	if [ "$OSTYPE" != "msys" ]; then
		install_debian_packages libffi-dev libssl-dev
	fi
	# Setup VENV
	if [ ! -e "$(pwd)/venv" ]; then
		if [ "$OSTYPE" == "msys" ]; then
			if [ -e /c/Python310/python.exe ]; then
				PYTHON3=/c/Python310/python.exe
			elif [ -e /usr/bin/python3.7 ]; then
				PYTHON3=/usr/bin/python3.7
			else
				PYTHON3="$(cygpath "C:\Program Files")/$(ls -1 "C:\Program Files" | grep "Python" | sort | tail -n 1)python.exe"
			fi
		else
			PYTHON3=/usr/bin/python3
			install_debian_packages python3-venv python3-pip python3-setuptools python3-wheel
		fi
		"$PYTHON3" -m venv "$(pwd)/venv"
		"$VENV/python" -m pip install --upgrade pip
		"$VENV/python" -m pip install setuptools wheel
	fi
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		if [ ! -e "$(pwd)/venv/$1.installed" ]; then
			"$VENV/python" -m pip install -r "$(pwd)/requirements_$1.txt"
			touch "$(pwd)/venv/$1.installed"
		fi
	fi
	if [ -e "$(pwd)/requirements.txt" ]; then
		PRJ="$(basename "$(dirname "$(realpath "$0")")")"
		if [ ! -e "$(pwd)/venv/${PRJ}.installed" ]; then
			"$VENV/python" -m pip install -r "$(pwd)/requirements.txt"
			touch "$(pwd)/venv/${PRJ}.installed"
		fi
	fi
	PATH="$VENV:$PATH"
}
