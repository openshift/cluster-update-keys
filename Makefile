all: base rhel
.PHONY: all

base:
	echo "# Release verification against OpenShift CI keys" > \
		manifests/0000_90_cluster-update-keys_configmap.yaml
	oc create configmap release-verification \
			--from-file=keys/verifier-public-key-openshift-ci \
			--from-file=stores/store-openshift-ci-release \
			--dry-run -o yaml | \
		oc annotate -f - release.openshift.io/verification-config-map= \
			-n openshift-config-managed --local --dry-run -o yaml	>> \
		manifests/0000_90_cluster-update-keys_configmap.yaml
	echo "  namespace: openshift-config-managed" >> \
		manifests/0000_90_cluster-update-keys_configmap.yaml
.PHONY: base

rhel:
.PHONY: rhel
