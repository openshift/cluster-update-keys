all: ci rhel
.PHONY: all

# The CI system uses the OpenShift CI public key and verifies it against a bucket on GCS.
ci:
	echo "# Release verification against OpenShift CI keys" > \
		manifests/0000_90_cluster-update-keys_configmap.yaml
	oc create configmap release-verification \
			--from-file=keys/verifier-public-key-openshift-ci \
			--from-file=stores/store-openshift-ci-release \
			--dry-run -o yaml | \
		oc annotate -f - release.openshift.io/verification-config-map= \
			-n openshift-config-managed --local --dry-run -o yaml	>> \
		manifests/0000_90_cluster-update-keys_configmap.yaml; \
	echo "  namespace: openshift-config-managed" >> \
		manifests/0000_90_cluster-update-keys_configmap.yaml
.PHONY: ci

# The Red Hat release contains the two primary Red Hat release keys from
# https://access.redhat.com/security/team/key as well as the beta 2 key. A future release
# will remove the beta 2 key from the trust relationship. The signature storage is a bucket
# on GCS and on mirror.openshift.com.
rhel:
	keydir=$(shell mktemp -d -t keys); \
	cat keys/verifier-public-key-redhat-release > "$$keydir/verifier-public-key-redhat"; \
	cat keys/verifier-public-key-redhat-beta-2 >> "$$keydir/verifier-public-key-redhat"; \
	echo "# Release verification against Official Red Hat keys" > \
		manifests.rhel/0000_90_cluster-update-keys_configmap.yaml; \
	oc create configmap release-verification -n openshift-config-managed \
			--from-file=$$keydir/verifier-public-key-redhat \
			--from-file=stores/store-openshift-official-release \
			--from-file=stores/store-openshift-official-release-mirror \
			--dry-run -o yaml | \
		oc annotate -f - release.openshift.io/verification-config-map= \
			-n openshift-config-managed --local --dry-run -o yaml	>> \
		manifests.rhel/0000_90_cluster-update-keys_configmap.yaml; \
	echo "  namespace: openshift-config-managed" >> \
		manifests.rhel/0000_90_cluster-update-keys_configmap.yaml
.PHONY: rhel
