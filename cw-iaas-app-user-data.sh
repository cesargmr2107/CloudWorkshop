#!/bin/bash

# Install apache web server
apt update -y
apt install -y apache2

# Enable and start apache2 service
systemctl enable apache2
systemctl start apache2