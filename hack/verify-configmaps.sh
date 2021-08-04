#!/usr/bin/env bash

./hack/generate-configmap.sh && git diff --exit-code
