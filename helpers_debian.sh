#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

install_debian_packages() { #helpmsg: Install a list of debian packages using sudo
	if [ -x "$(command -v apt-get)" ]; then
		check_commands dpkg-query sudo
		local package
		for package in "$@"; do
			if ! dpkg-query -f '${Status}' -s "$package" | grep 'install ok' 2>/dev/null 1>/dev/null; then
				echo "Installing $package"
				sudo apt-get -y install "$package"
			fi
		done
	else
		echo "apt-get not found. Ignoring installation of $*"
	fi
}
