#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Adding Trace Labs apt repository (apt.tracelabs.org)'
#### '----------------------------------------------------------------------
# Key fingerprint: 34CE 4BC7 4FC3 BFFE 7AD7 7C2A E7A5 76CA 1ABD 03CD
install -d -m 0755 "${INSTALL_DIR}/etc/apt/keyrings"
install -m 0644 "${KEYS_DIR}/tlosint-archive-keyring.gpg" \
    "${INSTALL_DIR}/etc/apt/keyrings/tlosint-archive-keyring.gpg"

cat > "${INSTALL_DIR}/etc/apt/sources.list.d/tlosint.sources" <<'EOF'
Types: deb
URIs: https://apt.tracelabs.org
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/tlosint-archive-keyring.gpg
EOF

#### '----------------------------------------------------------------------
info ' Adding trixie-backports (yt-dlp, gallery-dl, streamlink)'
#### '----------------------------------------------------------------------
# Backports are only used when explicitly selected with -t trixie-backports
cat > "${INSTALL_DIR}/etc/apt/sources.list.d/backports.sources" <<EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: ${DIST_CODENAME}-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

aptUpdate
