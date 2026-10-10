#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

# ==============================================================================
# Pinned versions. Bump a tool by changing its version (and checksum) here.
# ==============================================================================
MONOLITH_VERSION="v2.11.2"
MONOLITH_SHA256="392c1422a3bf31082d41d2c05fcc2ed8a675d2ab3aea65c5db5c82e43911d71b"
GOWITNESS_VERSION="3.2.0"
GOWITNESS_SHA256="d315bf505691ea64a87f6231a757acfee0a94c024ab3531f35b3c52dad15895e"
TWSCRAPE_VERSION="0.20.1"
# auto-archiver requires Python < 3.13 (trixie ships 3.13), so it runs from
# the upstream container image instead of pipx; same approach as tlosint-vm.
AUTO_ARCHIVER_IMAGE="bellingcat/auto-archiver:v1.2.9@sha256:f09475f7b118abdad0e0f761b926a31fb57aa2d4c724ef2fa6084070f064a8bb"

# /usr/local and /home are per-AppVM in Qubes, so anything installed there in
# the template is invisible to AppVMs. Non-apt tools live under /opt/tlosint
# and are symlinked into /usr/bin.
TLOSINT_DIR="/opt/tlosint"

#### '----------------------------------------------------------------------
info ' Installing yt-dlp, gallery-dl and streamlink from trixie-backports'
#### '----------------------------------------------------------------------
aptInstall -t "${DIST_CODENAME}-backports" yt-dlp gallery-dl streamlink

#### '----------------------------------------------------------------------
info ' Installing pinned release binaries (monolith, gowitness)'
#### '----------------------------------------------------------------------
mkdir -p "${INSTALL_DIR}${TLOSINT_DIR}/bin"

installReleaseBinary() {
    local name="$1"
    local url="$2"
    local sha256="$3"
    local dest="${TLOSINT_DIR}/bin/${name}"

    chroot_cmd curl -fsSL --retry 3 -o "${dest}" "${url}"
    echo "${sha256}  ${dest}" | chroot_cmd sha256sum -c -
    chmod 0755 "${INSTALL_DIR}${dest}"
}

installReleaseBinary monolith \
    "https://github.com/Y2Z/monolith/releases/download/${MONOLITH_VERSION}/monolith-gnu-linux-x86_64" \
    "${MONOLITH_SHA256}"
installReleaseBinary gowitness \
    "https://github.com/sensepost/gowitness/releases/download/${GOWITNESS_VERSION}/gowitness-${GOWITNESS_VERSION}-linux-amd64" \
    "${GOWITNESS_SHA256}"

#### '----------------------------------------------------------------------
info ' Installing pipx tools into /opt/tlosint (twscrape)'
#### '----------------------------------------------------------------------
chroot_cmd env \
    PIPX_HOME="${TLOSINT_DIR}/pipx" \
    PIPX_BIN_DIR="${TLOSINT_DIR}/bin" \
    PIPX_MAN_DIR="${TLOSINT_DIR}/share/man" \
    pipx install "twscrape==${TWSCRAPE_VERSION}"

#### '----------------------------------------------------------------------
info ' Installing auto-archiver container wrapper'
#### '----------------------------------------------------------------------
cat > "${INSTALL_DIR}${TLOSINT_DIR}/bin/auto-archiver" <<EOF
#!/usr/bin/env bash
set -euo pipefail
# The current directory is mounted at /data inside the container; point
# auto-archiver's config and output paths there. The image is pulled on
# first use and kept across reboots (see /etc/qubes-bind-dirs.d/).
TTY_FLAGS=(-i)
if [[ -t 0 && -t 1 ]]; then
    TTY_FLAGS=(-i -t)
fi
exec docker run --rm "\${TTY_FLAGS[@]}" -v "\${PWD}:/data" "${AUTO_ARCHIVER_IMAGE}" "\$@"
EOF
chmod 0755 "${INSTALL_DIR}${TLOSINT_DIR}/bin/auto-archiver"

# Keep pulled images in AppVMs; /var/lib is reset on every AppVM boot otherwise
mkdir -p "${INSTALL_DIR}/etc/qubes-bind-dirs.d"
cat > "${INSTALL_DIR}/etc/qubes-bind-dirs.d/50_tlosint-docker.conf" <<'EOF'
binds+=( '/var/lib/docker' )
EOF

#### '----------------------------------------------------------------------
info ' Linking /opt/tlosint/bin into /usr/bin'
#### '----------------------------------------------------------------------
for bin in "${INSTALL_DIR}${TLOSINT_DIR}"/bin/*; do
    ln -sf "${TLOSINT_DIR}/bin/${bin##*/}" "${INSTALL_DIR}/usr/bin/${bin##*/}"
done

#### '----------------------------------------------------------------------
info ' Checking that every tlosint tool is on PATH'
#### '----------------------------------------------------------------------
# TODO: confirm binary names shipped by the tlosint-* debs after the first build
required_bins=(
    carbon14 ghunt maigret metagoofil whatsmyname
    instaloader twscrape yt-dlp gallery-dl streamlink ffmpeg
    auto-archiver monolith gowitness ia httrack tesseract mat2 shred
    docker
)
missing=()
for bin in "${required_bins[@]}"; do
    chroot_cmd sh -c "command -v '${bin}'" >/dev/null || missing+=("${bin}")
done
if ! chroot_cmd sh -c 'command -v spiderfoot || command -v sf.py' >/dev/null; then
    missing+=("spiderfoot/sf.py")
fi
if [ "${#missing[@]}" -gt 0 ]; then
    error "tlosint tools missing from template: ${missing[*]}"
    exit 1
fi
