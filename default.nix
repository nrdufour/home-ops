{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = with pkgs.buildPackages; [
      just
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
