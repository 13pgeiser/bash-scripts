#!/bin/bash

# (C) P. Geiser
# MIT
# https://github.com/13pgeiser/bash-scripts.git

docker_configure() { #helpmsg: Basic compatibility for MSYS
	DOCKER_FLAGS=""
	if [ "$OSTYPE" == "msys" ]; then
		docker() {
			#MSYS_NO_PATHCONV=1 docker.exe "$@"
			# shellcheck disable=SC2317
			(
				# shellcheck disable=SC2317
				export MSYS_NO_PATHCONV=1
				# shellcheck disable=SC2317
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
	if [ ! -x "$(command -v docker)" ]; then
		echo "Docker not found. Skipping checks"
		return
	fi
	docker_configure
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

docker_setup() { #helpmsg: Setup variables for docker: image, volume, ...
	docker_configure
	# Image and volume names are prefixed by user name
	IMAGE_NAME="${USER}_$1"
	export IMAGE_NAME
	VOLUME_NAME="${USER}_home"
	export VOLUME_NAME
	DOCKERFILE="docker/Dockerfile"
	export DOCKERFILE
	DOCKER_BUILDKIT=1
	export DOCKER_BUILDKIT
	DOCKER_RUN_BASE="$DOCKER_RUN_CMD -v $VOLUME_NAME:/home/$USER -v $(pwd):/mnt --name ${IMAGE_NAME}_container"
	export DOCKER_RUN_BASE
	DOCKER_RUN_I="$DOCKER_RUN_BASE -i $IMAGE_NAME"
	export DOCKER_RUN_I
	DOCKER_RUN_IT="$DOCKER_RUN_BASE -it $IMAGE_NAME"
	export DOCKER_RUN_IT
}

docker_build_image_and_create_volume() { # create the volume for the home user and build the docker image
	docker volume create "$VOLUME_NAME"
	(

		cd docker || exit 1
		DOCKER_BUILDKIT=0 docker build -t "$IMAGE_NAME" . --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" --build-arg USER="$USER"
	)
}

dockerfile_create() { #helpmsg: Start the dockerfile
	mkdir -p docker
	cat >"$DOCKERFILE" <<'EOF'
# Automatically created!
# DO NOT EDIT!
FROM debian:bullseye-slim
# Configure current user
ARG USER=host_user
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $USER
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER
RUN mkdir -p /work
RUN chown -R ${USER}.${USER} /work
EOF
}

dockerfile_sudo() { #helpmsg: Setup sudo for current user
	cat >>"$DOCKERFILE" <<'EOF'
RUN set -ex \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
	sudo \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
RUN echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" >>/etc/sudoers
EOF
}

dockerfile_setup_python() { #helpmsg: Install python3 + pip + setuptools + venv
	cat >>"$DOCKERFILE" <<'EOF'
# Install the bare minimum to use python
RUN 	apt-get update && \
        apt-get dist-upgrade -y && \
        apt-get install -y --no-install-recommends \
                git \
                make \
                python3-pip \
                python3-setuptools \
                python3-venv \
                python3-wheel && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
EOF
	if [ -f ./requirements.txt ]; then
		cat <<EOF >>"$DOCKERFILE"
# Copy requirements and install them
COPY ./requirements.txt /
RUN python3 -m pip install -r requirements.txt
EOF
	fi
}

dockerfile_setup_debootstrap() { #helpmsg: Install debootstrap + qemu-user-static and build deps.
	cat >>"$DOCKERFILE" <<'EOF'
RUN set -ex \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
	bc \
	binfmt-support \
	bison \
	build-essential \
	ca-certificates \
	cpio \
	curl \
	debootstrap \
	device-tree-compiler \
	dh-exec \
	fakeroot \
	fdisk \
	figlet \
	flex \
	git \
	gzip \
	libssl-dev \
	kernel-wedge \
	kmod \
	ncurses-dev \
	parted \
	python \
	python3 \
	qemu-user-static \
	quilt \
	rsync \
	swig \
	u-boot-tools \
	udev \
	vboot-kernel-utils \
	wget \
	xz-utils \
	zip \
	zstd \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
EOF
}

dockerfile_switch_to_user() { #helpmsg: switch to the user in the dockerfile and set workdir
	cat >>"$DOCKERFILE" <<'EOF'
USER $USER
ENV PATH="/home/${USER}/.local/bin:${PATH}"
WORKDIR /mnt
EOF
}
