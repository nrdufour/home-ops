# Main justfile for home-ops

# Root directory
root_dir := justfile_directory()
kubernetes_dir := root_dir / "kubernetes"

# Environment variables
export KUBECONFIG := kubernetes_dir / "kubernetes/main/kubeconfig"
export SOPS_AGE_KEY_FILE := env_var('HOME') / ".config/sops/age/keys.txt"

# Import recipe files
import '.justfiles/k8s/justfile'
import '.justfiles/sops/justfile'

# Default recipe (list all recipes)
[private]
default:
    @just --list
