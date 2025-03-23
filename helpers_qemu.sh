#!/bin/bash

qemu_wait_for_ssh() { #helpmsg: Wait for SSH connection. Usage: wait_for_ssh "user@host" "port"
	install_debian_packages sshpass openssh-client
	local ret=-1
	while [ $ret -ne 0 ]; do
		sshpass -p insecure ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p "$2" "$1" 'cat /etc/hostname' 2>/dev/null >/dev/null && ret=$? || ret=$?
		if [ $ret -ne 0 ]; then
			echo -n "."
			sleep 10
		else
			echo "ready!"
		fi
	done
}

qemu_copy_ssh_keys() { #helpmsg: Copy public key for SSH connection. Usage: copy_ssh_keys "user@host" "port"
	install_debian_packages sshpass openssh-client
	if echo "$SSH_AUTH_SOCK" | grep gpg -q -v; then
		if [ ! -e "$HOME/.ssh/id_rsa" ]; then
			mkdir -p "$HOME/.ssh"
			ssh-keygen -t rsa -q -P "" -f "$HOME/.ssh/id_rsa"
		fi
	fi
	if [ ! -e "$HOME/.ssh/known_hosts" ]; then
		touch "$HOME/.ssh/known_hosts"
	fi
	echo ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[${1##*@}]:$2"
	ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[${1##*@}]:$2"
	echo sshpass -p insecure ssh-copy-id -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p "$2" "$1"
	sshpass -p insecure ssh-copy-id -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p "$2" "$1"
	echo ssh -p "$2" -o "StrictHostKeyChecking=accept-new" "$1" 'cat /etc/hostname'
	ssh -p "$2" -o "StrictHostKeyChecking=accept-new" "$1" 'cat /etc/hostname'
}

qemu_launch() { #helpmsg: Start QEMU. Usage: lauch_qemu "port" "disk_size" "cdrom"
	install_debian_packages qemu-system-x86 qemu-utils cpu-checker
	if [ ! -e hda.tmp ]; then
		qemu-img create -f qcow2 hda.tmp "$2"
	fi
	QEMU_CMD="qemu-system-x86_64"
	if [ ! -e OVMF_VARS_4M.ms.fd ]; then
		cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd .
	fi
	QEMU_CMD="$QEMU_CMD -machine q35"
	QEMU_CMD="$QEMU_CMD -drive if=pflash,format=raw,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd,readonly=on"
	QEMU_CMD="$QEMU_CMD -drive if=pflash,format=raw,unit=1,file=./OVMF_VARS_4M.ms.fd"
	QEMU_CMD="$QEMU_CMD \
    -pidfile qemu.pid \
    -hda hda.tmp \
    -cdrom $3 \
    -smp cpus=$(getconf _NPROCESSORS_ONLN) \
    -m 2048 \
    -daemonize \
    -vga qxl \
    -vnc :0 \
    -net nic,model=virtio \
    -net user,hostfwd=$1"
	if sudo kvm-ok; then
		if [ -w /dev/kvm ]; then
			QEMU_CMD="$QEMU_CMD -enable-kvm"
		fi
	fi
	echo "$QEMU_CMD"
	if fuser qemu.pid; then
		echo "Qemu is already running!"
	else
		$QEMU_CMD
	fi
}
