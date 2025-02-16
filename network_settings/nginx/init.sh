#!/bin/bash

echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
cat config.yaml > /etc/netplan/50-cloud-init.yaml

netplan apply
