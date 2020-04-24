all: ci rhel
.PHONY: all

OFFICIAL = keys/verifier-public-key-redhat-release keys/verifier-public-key-redhat-beta-2 stores/store-openshift-official-release stores/store-openshift-official-release-mirror

# The CI system uses the OpenShift CI public key and verifies it against a bucket on GCS.
ci: keys/verifier-public-key-openshift-ci stores/store-openshift-ci-release $(OFFICIAL)
	echo "# Release verification against OpenShift CI keys signed by the CI infrastructure and official Red Hat keys" >manifests/0000_90_cluster-update-keys_configmap.yaml
	hack/generate-configmap.sh $^ >>manifests/0000_90_cluster-update-keys_configmap.yaml
.PHONY: ci

# The Red Hat release contains the two primary Red Hat release keys from
# https://access.redhat.com/security/team/key as well as the beta 2 key. A future release
# will remove the beta 2 key from the trust relationship. The signature storage is a bucket
# on GCS and on mirror.openshift.com.
rhel: $(OFFICIAL)
	echo "# Release verification against Official Red Hat keys" >manifests.rhel/0000_90_cluster-update-keys_configmap.yaml
	hack/generate-configmap.sh $^ >>manifests.rhel/0000_90_cluster-update-keys_configmap.yaml
.PHONY: rhel
