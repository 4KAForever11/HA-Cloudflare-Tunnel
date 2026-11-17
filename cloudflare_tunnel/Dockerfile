ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base@sha256:6cc6bcf640d8dfd238590c0404825f831401a7754febd0f9f9c0c68c82d955b3
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG CLOUDFLARED_VERSION
ARG CLOUDFLARED_SHA256_AMD64
ARG CLOUDFLARED_SHA256_AARCH64

RUN apk add --no-cache ca-certificates curl jq \
    && case "${BUILD_ARCH}" in \
        amd64) asset_arch="amd64"; expected_sha256="${CLOUDFLARED_SHA256_AMD64}" ;; \
        aarch64) asset_arch="arm64"; expected_sha256="${CLOUDFLARED_SHA256_AARCH64}" ;; \
        *) echo "Unsupported BUILD_ARCH: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac \
    && test -n "${CLOUDFLARED_VERSION}" \
    && test -n "${expected_sha256}" \
    && curl --fail --location --silent --show-error \
        "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${asset_arch}" \
        --output /usr/local/bin/cloudflared \
    && echo "${expected_sha256}  /usr/local/bin/cloudflared" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/cloudflared \
    && apk del curl

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

CMD ["/run.sh"]
