#!/bin/bash

START_COMMAND=$1

echo "Deploying application..."

pkill -f app.py || true

eval $START_COMMAND

sleep 5

echo "Application deployed"