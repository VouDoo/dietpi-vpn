#!/bin/bash
#
# Create cron job to update DuckDNS domain.
#
# Note: this script is intended to run as root.

set -e

# set installation variables
user="duck"
group="duckdns"
home="/opt/duckdns"
config_fpath="${home}/config"
script_fpath="${home}/duck.sh"
log_fpath="/var/log/duckdns"
cron_fpath="/etc/cron.d/duckdns"

# create home directory
mkdir -p "${home}"
echo "Home directory \"${home}\" has been created."

# add group
addgroup --system "${group}"
echo "Group \"${group}\" has been added."

# add user
adduser --system \
	--ingroup "${group}" \
	--home "${home}" \
	--no-create-home \
	--disabled-login \
	"${user}"
echo "User \"${user}\" has been added."

# create configuration file
cat >"${config_fpath}" <<EOF
# DuckDNS domain to update
DOMAIN=changeit
# DuckDNS token for you account
TOKEN=changeit
EOF
chown "root:${group}" "${config_fpath}"
chmod 640 "${config_fpath}"
echo "Configuration file \"${config_fpath}\" has been created."

# create script file
cat >"${script_fpath}" <<EOF
#!/bin/sh
#
# Update DuckDNS domain.

now() {
	date --rfc-3339=seconds
}

. ${config_fpath}

response=\$(/usr/bin/curl -sk "https://www.duckdns.org/update?domains=\${DOMAIN}&token=\${TOKEN}&ip=")

case "\${response}" in
	"OK")
		echo "\$(now) successfully updated \${DOMAIN} domain" >>"${log_fpath}"
		;;
	"KO")
		echo "\$(now) failed to update \${DOMAIN} domain" >>"${log_fpath}"
		;;
	*)
		echo "\$(now) critical failure during the update attempt of the \${DOMAIN} domain: \${response}" >>"${log_fpath}"
		;;
esac
EOF
chown "root:${group}" "${script_fpath}"
chmod 750 "${script_fpath}"
echo "Script file \"${script_fpath}\" has been created."

# create log file
touch "${log_fpath}"
chown "root:${group}" "${log_fpath}"
chmod 660 "${log_fpath}"
echo "Log file \"${log_fpath}\" has been created."

# add cron job to run the DuckDNS script every 5 minutes
cat >"${cron_fpath}" <<EOF
SHELL=/bin/sh
*/5 * * * * ${user} ${script_fpath} >/dev/null 2>&1
EOF
chown "root:root" "${cron_fpath}"
chmod 644 "${cron_fpath}"
echo "Cron file \"${cron_fpath}\" has been created."

# unset installation variables
unset -v user group home config_fpath script_fpath log_fpath cron_fpath
