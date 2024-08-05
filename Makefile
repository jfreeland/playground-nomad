VM_NAME := nomad

brew:
	brew bundle install --file=Brewfile

reqs:
	@ansible-galaxy role install -r ansible/requirements.yml
	@ansible-galaxy collection install -r ansible/requirements.yml

.PHONY: ip
ip:
	@multipass info $(VM_NAME) --format json | jq -r '.info.nomad.ipv4[0]'

.PHONY: ssh
ssh:
	@multipass shell nomad

.PHONY: down
down:
	@./setup.sh down

.PHONY: up
up:
	@rm nomad-jobs/prometheus/prometheus.yml 2>/dev/null || true
	@rm nomad-jobs/grafana/provisioning/datasources/provisioner.yml 2>/dev/null || true
	@./setup.sh up

load:
	ab -n 1000000 -c 20 http://$(shell multipass info "$(VM_NAME)" --format json | jq -r '.info.nomad.ipv4[0]'):8080/
