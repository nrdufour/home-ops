#!/bin/bash

#
#  just making a bash script for now to remember what I've done so far
#

cd kubernetes/main

k apply --kustomize ./bootstrap/flux
flux create secret git gitea-access --url=ssh://git@git.home:2222/nrdufour/home-ops.git --private-key-file=~/.ssh/fluxcd-home-ops

cat ~/.config/sops/age/keys.txt |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin

k apply --kustomize ./flux/config
flux reconcile source git kubernetes
