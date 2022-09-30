#!/bin/sh
#
# Create cron job to update DuckDNS domain.
#
# Note: this script is intended to run as root.

# define where DuckDNS stuff will be installed
INSTALL_DUCKDNS_DIR=/opt/duckdns

# create directory
mkdir -p "${INSTALL_DUCKDNS_DIR}"

# create configuration file
cat >"${INSTALL_DUCKDNS_DIR}/config" <<EOF
DUCKDNS_DOMAIN=changeit
DUCKDNS_TOKEN=changeit
DUCKDNS_LOGFILE=/var/log/duck.log
EOF
chmod 600 "${INSTALL_DUCKDNS_DIR}/config"

# create script
cat >"${INSTALL_DUCKDNS_DIR}/duck.sh" <<EOF
#!/bin/sh
#
# Update DuckDNS domain.

log_datetime() {
	date --rfc-3339=seconds
}

. ${INSTALL_DUCKDNS_DIR}/config
res=\$(curl -sk "https://www.duckdns.org/update?domains=\${DUCKDNS_DOMAIN}&token=\${DUCKDNS_TOKEN}&ip=")
case "\${res}" in
	"OK")
		echo "\$(log_datetime) successfully updated \${DUCKDNS_DOMAIN} domain" >>\${DUCKDNS_LOGFILE}
		;;
	"KO")
		echo "\$(log_datetime) failed to update \${DUCKDNS_DOMAIN} domain" >>\${DUCKDNS_LOGFILE}
		;;
	*)
		echo "\$(log_datetime) critical failure during the update attempt of the \${DUCKDNS_DOMAIN} domain: \${res}" >>\${DUCKDNS_LOGFILE}
		;;
esac
EOF
chmod 744 "${INSTALL_DUCKDNS_DIR}/duck.sh"

# add cron job to run the DuckDNS script every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * ${INSTALL_DUCKDNS_DIR}/duck.sh >/dev/null 2>&1") | crontab -

# ensure cron systemd unit is enabled and running
systemctl enable --now cron
