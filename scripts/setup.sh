#!/bin/bash

APP_TYPE=$1

echo "Setting up runtime for: $APP_TYPE"

if [ "$APP_TYPE" == "python" ]; then
    python3 --version
    pip3 --version
fi