#!/bin/bash

echo Testing templates creation...

#
# If failed, install Helm plugin before
#
# helm plugin install https://github.com/karuppiah7890/helm-schema-gen --verify=false
# helm dependency build

helm template example . --debug

