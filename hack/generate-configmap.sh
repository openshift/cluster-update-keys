#!/bin/sh

set -e

NAMESPACE=openshift-config-managed
KEYDIR="$(mktemp -d -t keys-XXXXXXXX)"

teardown() {
	rm -rf "${KEYDIR}"
}

trap teardown EXIT

is_store() {
	test "${1}" != "${1/store/}"
}

STORES=""
for KEY in "${@}"
do
	if is_store "${KEY}"
	then
		STORES="${STORES} --from-file=${KEY}"
		continue
	fi
	BASE="$(basename "${KEY}")"
	gpg --dearmor < "${KEY}" >> "${KEYDIR}/keys.gpg"
done

gpg --enarmor < "${KEYDIR}/keys.gpg" > "${KEYDIR}/verifier-public-key-redhat"
sed -i 's/ARMORED FILE/PUBLIC KEY BLOCK/' "${KEYDIR}/verifier-public-key-redhat"
MANIFEST="$(oc -n "${NAMESPACE}" create configmap release-verification --from-file="${KEYDIR}/verifier-public-key-redhat" ${STORES} --dry-run -o yaml)"
echo "${MANIFEST}" | oc -n "${NAMESPACE}" annotate -f - release.openshift.io/verification-config-map= --local --dry-run -o yaml
