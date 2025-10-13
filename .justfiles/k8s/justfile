# Kubernetes recipes

# renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
prometheus_operator_version := "v0.80.0"

# Retrieve kubeconfig from the main cluster host
k8s-get-kubeconfig host="opi01.internal":
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Retrieving kubeconfig from {{host}}..."

    # Create the kubernetes/main directory if it doesn't exist
    mkdir -p {{kubernetes_dir}}/main

    # Retrieve the kubeconfig file via SSH
    ssh {{host}} 'sudo cat /etc/rancher/k3s/k3s.yaml' > {{kubernetes_dir}}/main/kubeconfig.tmp

    # Replace 127.0.0.1 with the VIP address (kube-vip)
    sed 's/127\.0\.0\.1/10.1.0.5/g' {{kubernetes_dir}}/main/kubeconfig.tmp > {{kubernetes_dir}}/main/kubeconfig

    # Clean up temporary file
    rm {{kubernetes_dir}}/main/kubeconfig.tmp

    echo "Kubeconfig saved to {{kubernetes_dir}}/main/kubeconfig"
    echo "The server URL has been updated to use the kube-vip VIP: 10.1.0.5"

# Bootstrap Flux on a cluster (default: main)
k8s-bootstrap cluster="main":
    #!/usr/bin/env bash
    set -euo pipefail

    # Check precondition: SOPS_AGE_KEY_FILE must exist
    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
        echo "Error: SOPS_AGE_KEY_FILE not found at $SOPS_AGE_KEY_FILE"
        exit 1
    fi

    echo "Installing Prometheus Operator CRDs..."
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
    kubectl --context {{cluster}} apply --server-side --force-conflicts --filename https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/{{prometheus_operator_version}}/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml

    echo "Installing Flux..."
    # TODO: see why --force-conflicts is actually needed, especially after a reconcile
    # Wonder if the install manifests are that different (seems related to limits and other helm deployment)
    kubectl --context {{cluster}} apply --server-side --force-conflicts --kustomize {{kubernetes_dir}}/{{cluster}}/bootstrap/flux

    echo "Applying gitea access and sops keys..."
    sops --decrypt {{kubernetes_dir}}/{{cluster}}/bootstrap/flux/gitea-access.sops.yaml | kubectl --context {{cluster}} apply --force-conflicts --server-side --filename -
    sops --decrypt {{kubernetes_dir}}/{{cluster}}/bootstrap/flux/sops-age.sops.yaml | kubectl --context {{cluster}} apply --server-side --filename -

    echo "Applying kustomizations..."
    kubectl --context {{cluster}} apply --server-side --kustomize {{kubernetes_dir}}/{{cluster}}/flux/config

    echo "Bootstrap complete!"
