#!/bin/bash

# GCP Setup Script for CMS Template
# Run this script to set up initial GCP resources

set -e

PROJECT_ID=${1:-"your-project-id"}
REGION="us-central1"
DB_PASSWORD=${2:-"$(openssl rand -base64 32)"}

echo "Setting up GCP project: $PROJECT_ID"
echo "Region: $REGION"
echo "Generated DB Password: $DB_PASSWORD"

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling GCP APIs..."
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Create service account for GitHub Actions
echo "Creating service account for CI/CD..."
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account" || true

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Generate service account key
echo "Generating service account key..."
gcloud iam service-accounts keys create sa-key.json \
  --iam-account=github-actions@$PROJECT_ID.iam.gserviceaccount.com

# Create initial resources
echo "Creating Artifact Registry..."
gcloud artifacts repositories create cms-images \
  --repository-format=docker \
  --location=$REGION \
  --description="CMS Docker images" || echo "Repository may already exist"

echo "Creating storage bucket..."
gsutil mb -l $REGION gs://$PROJECT_ID-cms-storage || echo "Bucket may already exist"

echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add these GitHub secrets:"
echo "   - GCP_PROJECT_ID: $PROJECT_ID"
echo "   - GCP_SA_KEY: $(cat sa-key.json | base64 -w 0)"
echo "   - DB_PASSWORD: $DB_PASSWORD"
echo "   - GCP_PROJECT_HASH: (get from Cloud Run service URLs after first deploy)"
echo ""
echo "2. Delete the sa-key.json file after adding to GitHub secrets"
echo "3. Push to main branch to trigger deployment"