#!/bin/bash

echo "# Preparing Wireguard folder"
./remove.sh

echo "# Installing Wireguard"
./install.sh

echo "# Adding Wireguard's user"
./add-client.sh

echo "# Wireguard installed"