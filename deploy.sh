#!/bin/bash
set -e  # Exit immediately if any command fails

# -------------------------------
# Configuration
# -------------------------------
PROJECT_ID="project-a98c66aa-d52e-47ff-b80"
REGION="europe-west4"
IMAGE_NAME="pl"
REPO_NAME="main-repo"
SERVICE_NAME="mob"
VERSION_FILE="version.txt"
DEFAULT_VERSION=1

ARTIFACT_REGISTRY="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME"

# -------------------------------
# Determine Version
# -------------------------------
if [ -f "$VERSION_FILE" ]; then
  CURRENT_VERSION=$(cat "$VERSION_FILE")
  NEW_VERSION=$((CURRENT_VERSION + 1))
else
  NEW_VERSION=$DEFAULT_VERSION
fi

VERSION="v${NEW_VERSION}"
echo "Building version: $VERSION"

# -------------------------------
# Ensure Artifact Registry exists
# -------------------------------
REPO_EXISTS=$(gcloud artifacts repositories list \
  --project="$PROJECT_ID" \
  --location="$REGION" \
  --format="value(name)" | grep "^$REPO_NAME$" || true)

if [ -z "$REPO_EXISTS" ]; then
  echo "Creating Artifact Registry repository..."
  gcloud artifacts repositories create "$REPO_NAME" \
    --repository-format=Docker \
    --location="$REGION" \
    --description="Docker repository for NGINX proxy" \
    --project="$PROJECT_ID"
fi

# -------------------------------
# Build and Push Docker Image using Cloud Build
# -------------------------------
echo "Building and pushing Docker image via Cloud Build..."
gcloud builds submit . \
  --project="$PROJECT_ID" \
  --tag="$ARTIFACT_REGISTRY/$IMAGE_NAME:$VERSION" \
  --tag="$ARTIFACT_REGISTRY/$IMAGE_NAME:latest"

# -------------------------------
# Deploy to Cloud Run
# -------------------------------
echo "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --image="$ARTIFACT_REGISTRY/$IMAGE_NAME:$VERSION" \
  --platform=managed \
  --region="$REGION" \
  --allow-unauthenticated \
  --project="$PROJECT_ID"

# -------------------------------
# Update Version File
# -------------------------------
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "Deployment completed successfully! Version: $VERSION"
