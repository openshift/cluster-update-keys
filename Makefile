all: ci rhel
.PHONY: all

# The CI system uses the OpenShift CI public key and verifies it against a bucket on GCS.
ci:
	keydir=$(shell mktemp -d -t keys-XXXXXXXX); \
	gpg --dearmor < keys/verifier-public-key-openshift-ci > "$$keydir/verifier-public-key-ci.gpg"; \
	gpg --dearmor < keys/verifier-public-key-openshift-ci-2 >> "$$keydir/verifier-public-key-ci.gpg"; \
	gpg --enarmor < "$$keydir/verifier-public-key-ci.gpg" > "$$keydir/verifier-public-key-ci"; \
	sed -i 's/ARMORED FILE/PUBLIC KEY BLOCK/' "$$keydir/verifier-public-key-ci"; \
	echo "# Release verification against OpenShift CI keys signed by the CI infrastructure" > \
		manifests/0000_90_cluster-update-keys_configmap.yaml; \
	oc create configmap release-verification \
			--from-file=$$keydir/verifier-public-key-ci \
			--from-file=stores/store-openshift-ci-release \
			--dry-run -o yaml | \
		oc annotate -f - release.openshift.io/verification-config-map= \
			include.release.openshift.io/ibm-cloud-managed="true" \
			include.release.openshift.io/self-managed-high-availability="true" \
			include.release.openshift.io/single-node-developer="true" \
			-n openshift-config-managed --local --dry-run=client -o yaml	>> \
		manifests/0000_90_cluster-update-keys_configmap.yaml; \
	echo "  namespace: openshift-config-managed" >> \
		manifests/0000_90_cluster-update-keys_configmap.yaml
.PHONY: ci

# The Red Hat release contains the two primary Red Hat release keys from
# https://access.redhat.com/security/team/key as well as the beta 2 key. A future release
# will remove the beta 2 key from the trust relationship. The signature storage is a bucket
# on GCS and on mirror.openshift.com.
rhel:
	keydir=$(shell mktemp -d -t keys-XXXXXXXX); \
	gpg --dearmor < keys/verifier-public-key-redhat-release > "$$keydir/verifier-public-key-redhat.gpg"; \
	gpg --dearmor < keys/verifier-public-key-redhat-beta-2 >> "$$keydir/verifier-public-key-redhat.gpg"; \
	gpg --enarmor < "$$keydir/verifier-public-key-redhat.gpg" > "$$keydir/verifier-public-key-redhat"; \
	sed -i 's/ARMORED FILE/PUBLIC KEY BLOCK/' "$$keydir/verifier-public-key-redhat"; \
	echo "# Release verification against Official Red Hat keys" > \
		manifests.rhel/0000_90_cluster-update-keys_configmap.yaml; \
	oc create configmap release-verification -n openshift-config-managed \
			--from-file=$$keydir/verifier-public-key-redhat \
			--from-file=stores/store-openshift-official-release \
			--from-file=stores/store-openshift-official-release-mirror \
			--dry-run=client -o yaml | \
		oc annotate -f - release.openshift.io/verification-config-map= \
			include.release.openshift.io/ibm-cloud-managed="true" \
			include.release.openshift.io/self-managed-high-availability="true" \
			include.release.openshift.io/single-node-developer="true" \
			-n openshift-config-managed --local --dry-run=client -o yaml	>> \
		manifests.rhel/0000_90_cluster-update-keys_configmap.yaml; \
	echo "  namespace: openshift-config-managed" >> \
		manifests.rhel/0000_90_cluster-update-keys_configmap.yaml
.PHONY: rhel
