#!/bin/bash

# This script is for installing influxdb 1.8.10

sudo dpkg -i influxdb_1.8.10_amd64.deb

sudo systemctl enable influxdb.service

sudo systemctl start influxdb.service