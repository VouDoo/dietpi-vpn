#!/bin/sh
#
# Create cron job to update DuckDNS domain.
#
# Note: this script is intended to run as root.

#
# Installation variables
#

TARGET_DIR="/opt/duckdns"
USER="duck"
GROUP="duckdns"
LOG_FILE="/var/log/duckdns"

#
# Logic of the script
#

# create directory
mkdir -p "${TARGET_DIR}"

# create group and user
addgroup --system "${GROUP}"
adduser --system \
	--ingroup "${GROUP}" \
	--home "${TARGET_DIR}" \
	--no-create-home \
	--disabled-login \
	"${USER}"

# create configuration file
config_path="${TARGET_DIR}/config"
cat >"${config_path}" <<EOF
# DuckDNS domain to update
DOMAIN=changeit
# DuckDNS token for you account
TOKEN=changeit
EOF
chown "root:${GROUP}" "${config_path}"
chmod 640 "${config_path}"

# create script
script_path="${TARGET_DIR}/duck.sh"
cat >"${script_path}" <<EOF
#!/bin/sh
#
# Update DuckDNS domain.

now() {
	date --rfc-3339=seconds
}

. ${TARGET_DIR}/config

res=\$(/usr/bin/curl -sk "https://www.duckdns.org/update?domains=\${DOMAIN}&token=\${TOKEN}&ip=")

case "\${res}" in
	"OK")
		echo "\$(now) successfully updated \${DOMAIN} domain" >>${LOG_FILE}
		;;
	"KO")
		echo "\$(now) failed to update \${DOMAIN} domain" >>${LOG_FILE}
		;;
	*)
		echo "\$(now) critical failure during the update attempt of the \${DOMAIN} domain: \${res}" >>${LOG_FILE}
		;;
esac
EOF
chown "root:${GROUP}" "${script_path}"
chmod 750 "${script_path}"

# create log file
touch "${LOG_FILE}" && \
	chown "root:${GROUP}" "${LOG_FILE}" && \
	chmod 660 "${LOG_FILE}"

# add cron job to run the DuckDNS script every 5 minutes
cron_path=/etc/cron.d/duckdns
cat >"${cron_path}" <<EOF
SHELL=/bin/sh
*/5 * * * * duck ${TARGET_DIR}/duck.sh >/dev/null 2>&1
EOF
chown "root:root" "${cron_path}"
chmod 644 "${cron_path}"
