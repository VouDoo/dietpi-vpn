# Deploy DietPi as VPN server

This repository contains resources to deploy DietPi as VPN on a Raspberry Pi.

## Instructions

1. [Download and extract the DietPi disk image](https://dietpi.com/docs/install/#1-download-and-extract-the-dietpi-disk-image)
2. [Flash the DietPi image](https://dietpi.com/docs/install/#2-flash-the-dietpi-image)
3. [Prepare the first boot](https://dietpi.com/docs/install/#3-prepare-the-first-boot)

    Preferably, we want to automate the base installation that happends at the first boot of the system.

    Everything is explained on this page: [How to do an automatic base installation at first boot (DietPi-Automation)](https://dietpi.com/docs/usage/#how-to-do-an-automatic-base-installation-at-first-boot-dietpi-automation).

    This repository has a custom [dietpi.txt](./dietpi.txt).
    Make a copy of this file, edit it at your convenience and then place it in the `/boot` directory.

4. Boot the system

    *The system preparation might take a little while to complete...*

5. Create cron job to automatically update the DuckDNS domain

    Copy and run the [duckdns.sh](scripts/duckdns.sh) convenience script and then, edit values in `/opt/duckdns/config`.

6. Install and configure WireGuard

    Run `dietpi-software install 172` and follow [the guide to install WireGuard as server](https://dietpi.com/docs/software/vpn/#wireguard).
