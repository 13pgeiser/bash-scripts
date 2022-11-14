#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

docker_configure() { #helpmsg: Basic compatibility for MSYS
	DOCKER_FLAGS=""
	if [ "$OSTYPE" == "msys" ]; then
		docker() {
			#MSYS_NO_PATHCONV=1 docker.exe "$@"
			(
				export MSYS_NO_PATHCONV=1
				"docker.exe" "$@"
			)
		}
		export -f docker
	else
		if [ "$(getent group docker)" ]; then
			DOCKER_FLAGS="--group-add $(getent group docker | cut -d: -f3) -v /var/run/docker.sock:/var/run/docker.sock"
		fi
	fi
	DOCKER_RUN_CMD="docker run --rm  $DOCKER_FLAGS -u $(id -u):$(id -g)"
	export DOCKER_RUN_CMD
}

run_shfmt_and_shellcheck() { #helpmsg: Execute shfmt and shellcheck
	docker_configure
	install_debian_packages parallel
	if [ -x "$(command -v parallel)" ]; then
		parallel -v "$DOCKER_RUN_CMD" -v "$PWD":/mnt mvdan/shfmt -w /mnt/{} ::: "$@"
		parallel -v "$DOCKER_RUN_CMD" -e SHELLCHECK_OPTS="" -v "$PWD":/mnt koalaman/shellcheck:stable -x {} ::: "$@"
	else
		for helper in "$@"; do
			echo "$helper"
			$DOCKER_RUN_CMD -v "$PWD":/mnt mvdan/shfmt -w /mnt/"$helper"
			$DOCKER_RUN_CMD -e SHELLCHECK_OPTS="" -v "$PWD":/mnt koalaman/shellcheck:stable -x "$helper"
		done
	fi
}
