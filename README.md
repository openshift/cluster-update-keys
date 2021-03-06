# Cluster Update Keys

The image generated by this repository contributes a ConfigMap to an OpenShift release image that instructs the cluster version operator to verify updates using the provided keys and stores before performing updates.

The config map must have the annotation `release.openshift.io/verification-config-map` which instructs the cluster version operator to verify payloads against OpenPGP signatures in the atomic container signature format.

The keys within the config map define how verification is performed:

```
verifier-public-key-*: One or more GPG public keys in ASCII form that must have signed the
                       release image by digest.

store-*: A URL (scheme file://, http://, or https://) location that contains signatures. These
         signatures are in the atomic container signature format. The URL will have the digest
         of the image appended to it as "<STORE>/<ALGO>=<DIGEST>/signature-<NUMBER>" as described
         in the container image signing format. The docker-image-manifest section of the
         signature must match the release image digest. Signatures are searched starting at
         NUMBER 1 and incrementing if the signature exists but is not valid. The signature is a
         GPG signed and encrypted JSON message. The file store is provided for testing only at
         the current time, although future versions of the CVO might allow host mounting of
         signatures.
```

See https://github.com/containers/image/blob/ab49b0a48428c623a8f03b41b9083d48966b34a9/docs/signature-protocols.md for a description of the signature store.

The OpenShift CI system uses the public key described here and signs releases at https://amd64.ocp.releases.ci.openshift.org/ once they are created. Nightly and OKD builds are signed with CI release key and signatures updated to openshift-ci-release GCS bucket/.
Official OCP builds are signed with Red Hat release key, signatures uploaded to openshift-release GCS bucket and mirrored to https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release
