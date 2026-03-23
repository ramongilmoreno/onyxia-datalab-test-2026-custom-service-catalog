#!/bin/bash
helm dependency update charts/stata
helm package charts/stata
helm repo index . --url https://raw.githubusercontent.com/ramongilmoreno/onyxia-datalab-test-2026-custom-service-catalog/refs/heads/main

# Examples of resources
# https://raw.githubusercontent.com/ramongilmoreno/onyxia-datalab-test-2026-custom-service-catalog/refs/heads/main/index.yaml
# https://raw.githubusercontent.com/ramongilmoreno/onyxia-datalab-test-2026-custom-service-catalog/refs/heads/main/charts/stata/values.yaml
