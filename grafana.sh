#!/bin/bash

# This script is for installing grafana 9.5.3

sudo apt-get install -y adduser libfontconfig1

sudo dpkg -i grafana_9.5.3_amd64.deb

sudo systemctl enable grafana-server.service

sudo systemctl start grafana-server.service