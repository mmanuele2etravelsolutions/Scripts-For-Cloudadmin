#!/bin/bash

dd if=/dev/zero of=/swapfile bs=1G count=5
# ls -la /
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
free -m
sysctl vm.swappiness=10
