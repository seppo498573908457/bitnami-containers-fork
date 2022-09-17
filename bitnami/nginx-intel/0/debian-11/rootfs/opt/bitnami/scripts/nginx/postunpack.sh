#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libnginx.sh
. /opt/bitnami/scripts/libfs.sh

# Auxiliar Functions

########################
# Unset HTTP_PROXY header to protect vs HTTPPOXY vulnerability
# Ref: https://www.digitalocean.com/community/tutorials/how-to-protect-your-server-against-the-httpoxy-vulnerability
# Globals:
#   NGINX_*
# Arguments:
#   None
# Returns:
#   None
#########################
nginx_patch_httpoxy_vulnerability() {
    debug "Unsetting HTTP_PROXY header..."
    echo '# Unset the HTTP_PROXY header' >>"${NGINX_CONF_DIR}/fastcgi_params"
    echo 'fastcgi_param  HTTP_PROXY         "";' >>"${NGINX_CONF_DIR}/fastcgi_params"
}

# Load NGINX environment variables
. /opt/bitnami/scripts/nginx-env.sh

# Remove unnecessary directories that come with the tarball
rm -rf "${BITNAMI_ROOT_DIR}/certs" "${BITNAMI_ROOT_DIR}/server_blocks"

# Ensure non-root user has write permissions on a set of directories
for dir in "$NGINX_VOLUME_DIR" "$NGINX_CONF_DIR" "$NGINX_INITSCRIPTS_DIR" "$NGINX_SERVER_BLOCKS_DIR" "${NGINX_CONF_DIR}/bitnami" "$NGINX_LOGS_DIR" "$NGINX_TMP_DIR"; do
    ensure_dir_exists "$dir"
    chmod -R g+rwX "$dir"
done

# Unset HTTP_PROXY header to protect vs HTTPPOXY vulnerability
nginx_patch_httpoxy_vulnerability

# Configure default HTTP port
nginx_configure_port "$NGINX_DEFAULT_HTTP_PORT_NUMBER"
# Configure default HTTPS port
nginx_configure_port "$NGINX_DEFAULT_HTTPS_PORT_NUMBER" "${BITNAMI_ROOT_DIR}/scripts/nginx/server_blocks/default-https-server-block.conf"

# shellcheck disable=SC1091

# Load additional libraries
. /opt/bitnami/scripts/libfs.sh

# Users can mount their html sites at /app
mv "${NGINX_BASE_DIR}/html" /app
ln -sf /app "${NGINX_BASE_DIR}/html"

# Users can mount their certificates at /certs
mv "${NGINX_CONF_DIR}/bitnami/certs" /certs
ln -sf /certs "${NGINX_CONF_DIR}/bitnami/certs"

ln -sf "/dev/stdout" "${NGINX_LOGS_DIR}/access.log"
ln -sf "/dev/stderr" "${NGINX_LOGS_DIR}/error.log"

# Configure default HTTPS port
nginx_configure_port "$NGINX_DEFAULT_HTTPS_PORT_NUMBER" "${NGINX_SERVER_BLOCKS_DIR}/default-https-server-block.conf"
