#!/bin/sh

# .spec.containers[0].image
# kubectl patch deployment simple --type=json -p='[{"op": "add", "path": "/spec/template/metadata/labels/this", "value": "that"}]'
# kubectl patch pod valid-pod --type='json' -p='[{"op": "replace", "path": "/spec/containers/0/image", "value":"new image"}]'

# kubectl --kubeconfig .kube/config -n minio get tenants.minio.min.io -o json | jq '.spec.console.image'
