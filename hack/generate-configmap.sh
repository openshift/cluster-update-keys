#!/usr/bin/env bash

# This script generates configmap/s set by arguments
#
# To create a CI configmap use the "--ci" option
# To create an RHEL configmap use the "--rhel" option
# To create both configmaps use the "--all" option or pass no arguments

set -e

trap teardown EXIT

teardown() {
	rm -rf "${TEMP_DIR}"
}

TEMP_DIR=$(mktemp -d -t keys-XXXXXXXX)
CONFIGMAP_FILENAME="0000_90_cluster-update-keys_configmap.yaml"

# Generates a public key specified by parameters in the TEMP_DIR directory
#
# $1 - Filename of the key which will be generated
# $2 and more - Verifier public keys
#
generate_public_key() {
	key_filename="${1}"; shift
	rm -f "${TEMP_DIR}/key.gpg"
	for key in "${@}"; do
		gpg --dearmor < "${key}" >> "${TEMP_DIR}/key.gpg"
	done
	gpg --enarmor < "${TEMP_DIR}/key.gpg" > "${TEMP_DIR}/${key_filename}"
	sed -i "s/ARMORED FILE/PUBLIC KEY BLOCK/" "${TEMP_DIR}/${key_filename}"
}

# Generates a configmap specified by parameters
#
# $1 - Filename of a generated key in the TEMP_DIR directory
# $2 - Manifests directory
# $3 and more - Store files
#
generate_configmap() {
	key_filename="${1}"; shift
	manifests_dir="${1}"; shift

	stores=()
	for store in "${@}"; do
		stores+=("--from-file=${store}")
	done

	oc create configmap release-verification -n openshift-config-managed \
		--from-file="${TEMP_DIR}/${key_filename}" \
		"${stores[@]}" \
		--dry-run=client -o yaml |
		oc annotate -f - release.openshift.io/verification-config-map= \
			include.release.openshift.io/ibm-cloud-managed=true \
			include.release.openshift.io/self-managed-high-availability=true \
			include.release.openshift.io/single-node-developer=true \
			-n openshift-config-managed --local --dry-run=client -o yaml \
			>>"${manifests_dir}/${CONFIGMAP_FILENAME}"
}

# Generates a CI configmap
#
generate_ci_configmap() {
	configmap_data_key="verifier-public-key-ci"
	manifests_dir="manifests/"
	keys=("keys/verifier-public-key-openshift-ci" "keys/verifier-public-key-openshift-ci-2")
	stores=("stores/store-openshift-ci-release")

	generate_public_key \
		"${configmap_data_key}" \
		"${keys[@]}"

	echo "# Release verification against OpenShift CI keys signed by the CI infrastructure" \
		>"${manifests_dir}/${CONFIGMAP_FILENAME}"

	generate_configmap \
		"${configmap_data_key}" \
		"${manifests_dir}" \
		"${stores[@]}"
}

# Generates a RHEL configmap
#
generate_rhel_configmap() {
	configmap_data_key="verifier-public-key-redhat"
	manifests_dir="manifests.rhel/"
	keys=("keys/verifier-public-key-redhat-release" "keys/verifier-public-key-redhat-beta-2")
	stores=("stores/store-openshift-official-release" "stores/store-openshift-official-release-mirror")

	generate_public_key \
		"${configmap_data_key}" \
		"${keys[@]}"

	echo "# Release verification against Official Red Hat keys" \
		>"${manifests_dir}/${CONFIGMAP_FILENAME}"

	generate_configmap \
		"${configmap_data_key}" \
		"${manifests_dir}" \
		"${stores[@]}"
}

main() {
	if [ "$#" -eq "0" ]; then
		set -- --all
	fi

	while test "${#}" -gt 0; do
		case "${1}" in
		--ci)
			generate_ci_configmap
			shift
			;;
		--rhel)
			generate_rhel_configmap
			shift
			;;
		--all)
			generate_ci_configmap
			generate_rhel_configmap
			shift
			;;
		*)
			echo "unrecognized argument: ${1}" >&2
			exit 1
			;;
		esac
	done
}

main "$@"
