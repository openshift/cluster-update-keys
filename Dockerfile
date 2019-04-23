FROM scratch
COPY manifests/ /manifests/
LABEL description="This image contains the trusted keys for the updates delivered to a cluster."