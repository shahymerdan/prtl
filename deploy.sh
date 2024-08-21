#!/bin/bash

# Set variables
PROJECT_ID=642226031510
REGION=europe-west1
IMAGE_NAME=golan
ARTIFACT_REGISTRY_LOCATION=$REGION-docker.pkg.dev
REPO_NAME=main-repo
SERVICE_NAME=ken
VERSION_FILE=version.txt
DEFAULT_VERSION=1

# Determine the current version
if [ -f $VERSION_FILE ]; then
  CURRENT_VERSION=$(cat $VERSION_FILE)
  if [ "$CURRENT_VERSION" -eq "$DEFAULT_VERSION" ]; then
    NEW_VERSION=$((CURRENT_VERSION + 1))
  else
    NEW_VERSION=$((CURRENT_VERSION + 1))
  fi
else
  NEW_VERSION=$DEFAULT_VERSION
fi

# Format version as vN
VERSION="v${NEW_VERSION}"

# Check if Artifact Registry repository exists
REPO_EXISTS=$(gcloud artifacts repositories list --project=$PROJECT_ID --location=$REGION --format="value(name)" | grep "^$REPO_NAME$")

if [ -z "$REPO_EXISTS" ]; then
  echo "Creating Artifact Registry repository..."
  gcloud artifacts repositories create $REPO_NAME \
    --repository-format=Docker \
    --location=$REGION \
    --description="Docker repository for NGINX proxy" \
    --project=$PROJECT_ID
fi

# Build Docker image
echo "Building Docker image with version ${VERSION}..."
docker build -t $ARTIFACT_REGISTRY_LOCATION/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$VERSION .

# Push Docker image to Artifact Registry
echo "Pushing Docker image to Artifact Registry..."
docker push $ARTIFACT_REGISTRY_LOCATION/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$VERSION

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image=$ARTIFACT_REGISTRY_LOCATION/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$VERSION \
  --platform=managed \
  --region=$REGION \
  --allow-unauthenticated \
  --project=$PROJECT_ID

# Update the version file
echo $NEW_VERSION > $VERSION_FILE

echo "Deployment completed with version ${VERSION}."
