#!/bin/bash
# DuckDNS installer script for Wireguard exploitation
DOMAINS=YOUR DOMAIN
TOKEN=YOUR-SECRET-TOKEN
mkdir /opt/duckdns
tee /opt/duckdns/duck.sh <<EOF
echo url="https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ip=" | curl -k -o /var/log/duck.log -K -
EOF
chmod 700 /opt/duckdns/duck.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/duckdns/duck.sh >/dev/null 2>&1") | crontab -
systemctl start cron
