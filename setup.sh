#!/usr/bin/env bash

set -euo pipefail

SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa_jfreeland.pub"

VM_NAME="nomad"
VM_USER="ubuntu"
VM_MEMORY="2G"
UBUNTU_VERSION="jammy"

if [[ -z $(command multipass) || -z $(command -v ansible-galaxy) || -z $(command -v ansible-playbook) ]]; then
	echo "you must have multipass and ansible available."
	echo ""
	echo "this is a very opinionated process.  i used brew.  you can use apt, nix, however you want to get them installed."
	exit 1
fi

prompt_for_ssh_key() {
	if [[ -z "$SSH_PUB_KEY_PATH" ]]; then
		read -r -p "Enter the path to your SSH public key: " SSH_PUB_KEY_PATH
	fi
	if [[ ! -f "$SSH_PUB_KEY_PATH" ]]; then
		echo "The file $SSH_PUB_KEY_PATH does not exist."
		exit 1
	fi
}

# Function to create the cloud-init configuration file
create_cloud_init() {
	SSH_PUBLIC_KEY=$(cat "$SSH_PUB_KEY_PATH")
	CLOUD_INIT_CONFIG=$(
		cat <<EOF
#cloud-config
users:
  - default
  - name: ubuntu
    ssh_authorized_keys:
      - $SSH_PUBLIC_KEY
EOF
	)
	echo "$CLOUD_INIT_CONFIG" >cloud-init.yaml
}

create_multipass_vm() {
	multipass launch --name "$VM_NAME" --memory "$VM_MEMORY" --cloud-init cloud-init.yaml "$UBUNTU_VERSION" 2>/dev/null || true
	multipass mount ./nomad-jobs nomad:/mnt/nomad-jobs 2>/dev/null || true
}

generate_hosts_file() {
	NOMAD_IP="$(multipass info "$VM_NAME" --format json | jq -r '.info.nomad.ipv4[0]')"
	echo "[nomad]" >ansible/hosts.ini
	echo "${NOMAD_IP} ansible_user=${VM_USER}" >>ansible/hosts.ini
}

publish_endpoint() {
	NOMAD_IP="$(multipass info "$VM_NAME" --format json | jq -r '.info.nomad.ipv4[0]')"
	echo "you can access nomad at http://${NOMAD_IP}:4646/ to see job state."
	echo "you can access consul at http://${NOMAD_IP}:8500/ to see services state."
	echo
	echo "you can run 'make load' to throw some load at the server.  edit the Makefile to play with params."
	echo "you can also just curl http://${NOMAD_IP}:8080/ a couple times."
	echo
	echo "you can view grafana at http://${NOMAD_IP}:3000/ and check out the 'playing around' dashboard."
	echo "you can view prometheus at http://${NOMAD_IP}:9090/"
}

# TODO: I don't have time to add this right now. I could instruct the user that
# they need to add insecure registries if they want to push their own image but
# that's obnoxious too.
#
# I don't want to have to add HTTPS in front of the registry and handle fake auth.
#
# I just built and pushed the image to dockerhub for now.
# docker buildx build --push --platform linux/amd64,linux/arm64 -t joeyfreeland/helloworld:ok .
#build_and_push_helloworld() {}

if [[ $1 == "up" ]]; then
	prompt_for_ssh_key
	create_cloud_init
	create_multipass_vm
	generate_hosts_file
	ansible-playbook -i ansible/hosts.ini ansible/nomad.yml
	#build_and_push_helloworld
	ansible-playbook -i ansible/hosts.ini ansible/nomad_jobs.yml
	publish_endpoint
fi

if [[ $1 == "down" ]]; then
	multipass delete -p nomad 2>/dev/null || true
	rm cloud-init.yaml 2>/dev/null || true
	echo "multipass vm nomad deleted."
fi
