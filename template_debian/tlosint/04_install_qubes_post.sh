#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# shellcheck source=template_debian/vars.sh
source "${TEMPLATE_CONTENT_DIR}/vars.sh"
# shellcheck source=template_debian/distribution.sh
source "${TEMPLATE_CONTENT_DIR}/distribution.sh"

#### '----------------------------------------------------------------------
info ' Letting the default qube user run docker (auto-archiver)'
#### '----------------------------------------------------------------------
# 'user' is created by the Qubes packages installed in 04_install_qubes.sh
if chroot_cmd id user >/dev/null 2>&1; then
    chroot_cmd usermod -aG docker user
else
    error "Qubes default user 'user' not found; auto-archiver will need sudo"
fi
