#!/bin/bash
set -e  # Exit on any error

# -------------------------------
# Configuration
# -------------------------------
PROJECT_ID="project-ce3fe345-d3c0-4f4d-bee"
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
# Build Docker Image with Tags
# -------------------------------
echo "Building Docker image..."
docker build \
  -t "$ARTIFACT_REGISTRY/$IMAGE_NAME:$VERSION" \
  -t "$ARTIFACT_REGISTRY/$IMAGE_NAME:latest" .

# -------------------------------
# Push Docker Image
# -------------------------------
echo "Pushing Docker image..."
docker push "$ARTIFACT_REGISTRY/$IMAGE_NAME:$VERSION"
docker push "$ARTIFACT_REGISTRY/$IMAGE_NAME:latest"

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
echo "Deployment complete! Version: $VERSION"
