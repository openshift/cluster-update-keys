ci_keys = keys/verifier-public-key-openshift-ci keys/verifier-public-key-openshift-ci-2
ci_stores = stores/store-openshift-ci-release
ci_manifests = manifests/0000_90_cluster-update-keys_configmap.yaml
rhel_keys = keys/verifier-public-key-redhat-release keys/verifier-public-key-redhat-beta-2
rhel_stores = stores/store-openshift-official-release stores/store-openshift-official-release-mirror
rhel_manifests = manifests.rhel/0000_90_cluster-update-keys_configmap.yaml

all: ci rhel
.PHONY: all

# The CI system uses the OpenShift CI public key and verifies it against a bucket on GCS.
ci: $(ci_manifests)
.PHONY: ci

# The Red Hat release contains the two primary Red Hat release keys from
# https://access.redhat.com/security/team/key as well as the beta 2 key. A future release
# will remove the beta 2 key from the trust relationship. The signature storage is a bucket
# on GCS and on mirror.openshift.com.
rhel: $(rhel_manifests)
.PHONY: rhel

$(ci_manifests): hack/generate-configmap.sh $(ci_keys) $(ci_stores)
	$< --ci

$(rhel_manifests): hack/generate-configmap.sh $(rhel_keys) $(rhel_stores)
	$< --rhel
