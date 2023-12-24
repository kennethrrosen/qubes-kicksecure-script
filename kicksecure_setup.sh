#!/bin/bash

read -p "Choose repository type (A for Clearnet over Tor, B for Onion): " repo_choice
read -p "Do you want to onionize Debian repositories? (yes/no): " onionize_choice

if ! qvm-ls | grep -q debian-12-minimal; then
    qvm-template install debian-12-minimal
fi

qvm-clone debian-12-minimal kicksecure-17

qvm-run --pass-io kicksecure-17 'sudo apt update -y && sudo apt full-upgrade -y && sudo apt install --no-install-recommends -y sudo adduser'
qvm-run --pass-io kicksecure-17 'sudo /usr/sbin/addgroup --system console'
qvm-run --pass-io kicksecure-17 'sudo /usr/sbin/adduser user console'
qvm-run --pass-io kicksecure-17 'sudo /usr/sbin/adduser user sudo'
qvm-shutdown --wait kicksecure-17 && qvm-start kicksecure-17

if [ "$repo_choice" = "A" ]; then
    qvm-run --pass-io kicksecure-17 'sudo sed -i "s|Uris: https|Uris: tor+https|" /etc/apt/sources.list.d/extrepo_kicksecure.sources'
    elif [ "$repo_choice" = "B" ]; then
    qvm-run --pass-io kicksecure-17 'sudo sed -i "/^Uris:/c\Uris: tor+http://deb.w5j6stm77zs6652pgsij4awcjeel3eco7kvipheu6mtr623eyyehj4yd.onion" /etc/apt/sources.list.d/extrepo_kicksecure.sources'
fi

qvm-run --pass-io kicksecure-17 'export http_proxy=http://127.0.0.1:8082 && export https_proxy=http://127.0.0.1:8082 && sudo apt install -y extrepo && sudo extrepo enable kicksecure'
qvm-run --pass-io kicksecure-17 'sudo apt update && sudo apt full-upgrade && sudo apt install --no-install-recommends -y apt-transport-tor'
qvm-run --pass-io kicksecure-17 'sudo apt update -y && sudo apt full-upgrade -y && sudo apt install --no-install-recommends -y kicksecure-qubes-gui kicksecure-qubes-cli'
qvm-run --pass-io kicksecure-17 'sudo extrepo disable kicksecure'
qvm-run --pass-io kicksecure-17 'sudo mv /etc/apt/sources.list ~/'
qvm-run --pass-io kicksecure-17 'sudo touch /etc/apt/sources.list'

if [ "$onionize_choice" = "yes" ]; then
    qvm-run --pass-io kicksecure-17 'sudo sed -i "s|^deb tor+https://|## deb tor+https://|g" /etc/apt/sources.list.d/debian.list'
    qvm-run --pass-io kicksecure-17 'sudo sed -i "s|^#deb tor+http://|deb tor+http://|g" /etc/apt/sources.list.d/debian.list'
    qvm-run --pass-io kicksecure-17 'sudo sed -i "/fasttrack/d" /etc/apt/sources.list.d/debian.list'
    qvm-run --pass-io kicksecure-17 'sudo apt update && sudo apt full-upgrade'
fi

echo "Kicksecure-17 template created."
