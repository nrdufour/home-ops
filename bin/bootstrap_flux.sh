#!/bin/bash

#
#  just making a bash script for now to remember what I've done so far
#

cd kubernetes/main

k apply --kustomize ./bootstrap/
flux create secret git gitea-access --url=ssh://git@git.home:2222/nrdufour/home-ops.git --private-key-file=~/.ssh/fluxcd-home-ops
k apply --kustomize ./cluster/flux-system/
flux reconcile source git kubernetes
