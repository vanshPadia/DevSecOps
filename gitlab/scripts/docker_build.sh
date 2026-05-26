#!/bin/sh

set -e

docker --version
echo "Using Dockerfile path:Training/vansh"
echo "Using image name:testimage"
echo "Building Docker image testimage:$IMAGE_TAG..."
cd Training/vansh/
docker build -t testimage:"$IMAGE_TAG" .