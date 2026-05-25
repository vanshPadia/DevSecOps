#!/bin/bash

APP_TYPE=$1

echo "Setting up runtime for: $APP_TYPE"

if [ "$APP_TYPE" == "python" ]; then
    apt update
    apt install -y python3 python3-pip
fi