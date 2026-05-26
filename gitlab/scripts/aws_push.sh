#!/bin/sh

set -e

apk add aws-cli
aws --version
echo ECR Registry:"$ECR_REGISTRY_URI"
echo ECR Repository:try    
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY_URI"

ECR_IMAGE_URI="$ECR_REGISTRY_URI/try:$IMAGE_TAG"
echo "Tagging image for ECR:$ECR_IMAGE_URI"
docker tag "testimage:$IMAGE_TAG" "$ECR_IMAGE_URI"
echo "Pushing image to ECR:$ECR_IMAGE_URI"
docker push "$ECR_IMAGE_URI"