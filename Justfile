set export

ROOT_DIR := justfile_directory()
HOME_DIR := env_var('HOME')

ANSIBLE_DIR := ROOT_DIR / "ansible"
KUBERNETES_DIR := ROOT_DIR / "kubernetes"

# Ansible related variables
VIRTUAL_ENV := ROOT_DIR / ".venv"
ANSIBLE_COLLECTIONS_PATH := VIRTUAL_ENV / "galaxy"
ANSIBLE_ROLES_PATH := VIRTUAL_ENV / "galaxy/ansible_roles"
ANSIBLE_VARS_ENABLED := "host_group_vars,community.sops.sops"

# list available commands
default:
	@just --list

# --- Ansible ---

# Create the ansible virtualenv
venv:
	cd {{ROOT_DIR}} && python3 -m venv .venv
	{{VIRTUAL_ENV}}/bin/python3 -m pip install --upgrade pip setuptools wheel
	{{VIRTUAL_ENV}}/bin/python3 -m pip install --upgrade --requirement {{ANSIBLE_DIR}}/requirements.txt
	{{VIRTUAL_ENV}}/bin/ansible-galaxy install --role-file "{{ANSIBLE_DIR}}/requirements.yml"

# --- Flux ---

# Bootstrap Flux
flux_bootstrap:
	kubectl --context main apply --kustomize {{KUBERNETES_DIR}}/main/bootstrap/flux
	-flux create secret git gitea-access \
		--url=ssh://git@git.home:2222/nrdufour/home-ops.git \
		--private-key-file={{HOME_DIR}}/.ssh/fluxcd-home-ops

	-cat {{HOME_DIR}}/.config/sops/age/keys.txt | \
		kubectl --context main create secret generic sops-age \
		--namespace=flux-system \
		--from-file=age.agekey=/dev/stdin

	kubectl --context main apply --kustomize {{KUBERNETES_DIR}}/main/flux/config
	flux reconcile source git home-ops-kubernetes

