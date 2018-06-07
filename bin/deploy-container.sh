#!/bin/bash
#
# deploy-container.sh
#
# This is a simple helper script to deploy a container to amazon ecr.

CONTAINER="tesera/ktpi"
ACCOUNT="073688489507"
REGION="us-west-2"
ECR_IMAGE_NAME="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${CONTAINER}"

# Login to AWS ECR
eval `aws ecr get-login --no-include-email --region ${REGION}`

# Create a repository for $CONTAINER if not exists
if [[ -z `aws ecr describe-repositories | grep "$CONTAINER"` ]]; then
  echo "Creating Repository"
  REPO_CREATED=`aws ecr create-repository --repository-name "$CONTAINER"`
fi

# Tag latest $CONTAINER image
docker tag "${CONTAINER}:latest" $ECR_IMAGE_NAME

# Push image to AWS ECR
docker push $ECR_IMAGE_NAME

# Remove pesky tagged image
docker rmi $ECR_IMAGE_NAME
