#!/bin/bash

# This script verifies environment variables and triggers another script for installation.

if [ $CHRONOGRAF=="yes" ]; then
    sudo sh chronograf.sh
fi
if [ $INFLUX=="yes" ]; then
    sudo sh influxdb.sh
fi
if [ $GRAFANA=="yes" ]; then
    sudo sh grafana.sh
fi
