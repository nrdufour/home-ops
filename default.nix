{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = with pkgs.buildPackages; [
      go-task
      kubectl
      kubectl-cnpg
      fluxcd
      kubernetes-helm
      jq
      yamllint
      cmctl
      argocd
    ];
}
