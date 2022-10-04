#!/bin/sh
#
# Install WireGuard
#
# Note: this script is intended to run as root.

# install packages with APT
apt-get update -y && apt-get install -y \
	wireguard-dkms \
	wireguard-tools \
	qrencode
