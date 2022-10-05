#!/bin/bash
#
# Install WireGuard.
#
# Note: this script is intended to run as root.

set -e

# read script parameters
if [[ $# -ge 1 ]]
then
	domain_name=$1
	shift
else
	domain_name="$(hostname)"
fi

# set installation variables
server_ipv4=$(ip -4 -br addr show eth0 | awk -F" " '{print $3}' | cut -d'/' -f1)
server_port="51820"
server_conf="/etc/wireguard/wg0.conf"
server_key="/etc/wireguard/server_private.key"
server_pub="/etc/wireguard/server_public.key"
client_conf="/etc/wireguard/wg0-client.conf"
client_key="/etc/wireguard/client_private.key"
client_pub="/etc/wireguard/client_public.key"

# download latest package list
apt-get update -yq

# install kernel headers and matching kernel image,
# as is required for wireguard-dkms to build the WireGuard kernel module
apt-get install -yq \
	raspberrypi-kernel \
	raspberrypi-kernel-headers \
	raspberrypi-bootloader

# install packages with APT
apt-get install -yq \
	wireguard-dkms \
	wireguard-tools \
	qrencode
echo "Packages have been installed."

# set default file permissions for newly created files,
# equivalent to `chmod 600`
umask a=,u=rw

# create key pair for server
[[ -f "${server_key}" ]] || wg genkey > "${server_key}"
[[ -f "${server_pub}" ]] || wg pubkey < "${server_key}" > "${server_pub}"
echo "Server key pair has been generated."

# create key pair for client
[[ -f "${client_key}" ]] || wg genkey > "${client_key}"
[[ -f "${client_pub}" ]] || wg pubkey < "${client_key}" > "${client_pub}"
echo "Client key pair has been generated."

# create server configuration
[[ -f "${server_conf}" ]] || cat >"${server_conf}" <<EOF
[Interface]
Address = 10.9.0.1/24
PrivateKey = $(<"${server_key}")
ListenPort = ${server_port}

PostUp = sysctl net.ipv4.conf.%i.forwarding=1 net.ipv4.conf.$(ip r l 0/0 | mawk '{print $5;exit}').forwarding=1
PostUp = sysctl net.ipv6.conf.$(ip r l 0/0 | mawk '{print $5;exit}').accept_ra=2
PostUp = sysctl net.ipv6.conf.%i.forwarding=1 net.ipv6.conf.$(ip r l 0/0 | mawk '{print $5;exit}').forwarding=1
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o $(ip r l 0/0 | mawk '{print $5;exit}') -j MASQUERADE
PostUp = ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $(ip r l 0/0 | mawk '{print $5;exit}') -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.9.0.0/24 -o $(ip r l 0/0 | mawk '{print $5;exit}') -j MASQUERADE
PostDown = ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $(ip r l 0/0 | mawk '{print $5;exit}') -j MASQUERADE

[Peer]
PublicKey = $(<"${client_pub}")
AllowedIPs = 10.9.0.2/32
EOF
echo "Server configuration has been created."

# create client configuration
[[ -f "${client_conf}" ]] || cat >"${client_conf}" <<EOF
[Interface]
Address = 10.9.0.2/24
PrivateKey = $(<"${client_key}")
# Comment the following to preserve the clients default DNS server, or force a desired one.
DNS = 192.168.1.1
# Kill switch: Uncomment the following, if the client should stop any network traffic, when disconnected from the VPN server
# NB: This requires "iptables" to be installed, thus will not work on most mobile phones.
#PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT; ip6tables -I OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
#PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT; ip6tables -D OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT

[Peer]
PublicKey = $(<"${server_pub}")
# Tunnel all network traffic through the VPN:
#	AllowedIPs = 0.0.0.0/0, ::/0
# Tunnel access to server-side local network only:
#	AllowedIPs = ${server_ipv4%.*}.0/24
# Tunnel access to VPN server only:
#	AllowedIPs = ${server_ipv4}/32
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${domain_name}:${server_port}
# Uncomment the following, if you're behind a NAT and want the connection to be kept alive.
#PersistentKeepalive = 25
EOF
echo "Client configuration has been created."

# unset installation variables
unset -v \
	server_ipv4 server_port server_conf server_key server_pub \
	client_conf client_key client_pub \
	domain_name

# start service and enable autostart at bootup
systemctl enable --now wg-quick@wg0-client
echo "Service has been started."
