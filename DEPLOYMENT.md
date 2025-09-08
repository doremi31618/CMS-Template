# GCP Deployment Guide

This guide covers setting up CI/CD pipeline for your CMS Template on Google Cloud Platform.

## Infrastructure Overview

- **Cloud Run**: Frontend and Backend services
- **Cloud SQL**: PostgreSQL database
- **Cloud Storage**: File storage bucket
- **Artifact Registry**: Docker image storage
- **GitHub Actions**: CI/CD pipeline

## Initial Setup

### 1. Run GCP Setup Script

```bash
./gcp-setup.sh your-project-id
```

This script will:
- Enable required GCP APIs
- Create service accounts and permissions
- Create initial resources (Artifact Registry, Storage bucket)
- Generate service account key

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `GCP_PROJECT_ID` | Your GCP project ID | `my-cms-project` |
| `GCP_SA_KEY` | Service account JSON key (base64 encoded) | Output from setup script |
| `DB_PASSWORD` | PostgreSQL database password | Generated secure password |
| `GCP_PROJECT_HASH` | Cloud Run service hash | Get from service URLs after first deploy |

### 3. Update Environment Files

**Backend (.env.example):**
- Update `GCP_PROJECT_ID` and `STORAGE_BUCKET`
- Set production database credentials

**Frontend (.env.example):**
- Update `NEXT_PUBLIC_API_URL` for production
- Update `NEXT_PUBLIC_STORAGE_BUCKET`

## CI/CD Pipeline

### Trigger Conditions
- **Push to `main`**: Production deployment
- **Push to `staging`**: Staging deployment
- **Pull Request to `main`**: Tests only

### Pipeline Stages

1. **Test Stage**
   - Install dependencies
   - Run linting and type checking
   - Execute tests

2. **Infrastructure Setup**
   - Enable GCP APIs
   - Create/verify Cloud SQL instance
   - Create/verify storage bucket
   - Setup Artifact Registry

3. **Build & Deploy**
   - Build Docker images
   - Push to Artifact Registry
   - Deploy to Cloud Run
   - Run database migrations
   - Output service URLs

## Services Configuration

### Cloud SQL (PostgreSQL)
- **Instance**: `cms-postgres`
- **Database**: `cms_production`
- **Region**: `us-central1`
- **Tier**: `db-f1-micro` (development)

### Cloud Storage
- **Bucket**: `{PROJECT_ID}-cms-storage`
- **Location**: `us-central1`
- **Public access**: Read-only for uploaded files

### Cloud Run Services
- **Frontend**: `cms-frontend`
- **Backend**: `cms-backend`
- **Region**: `us-central1`
- **Memory**: 512Mi (frontend), 1Gi (backend)

## Environment Variables

### Frontend Service
- `NODE_ENV=production`
- `NEXT_PUBLIC_API_URL`: Backend service URL
- `NEXT_PUBLIC_STORAGE_BUCKET`: Storage bucket name

### Backend Service
- `NODE_ENV=production`
- `HOST=0.0.0.0`
- `PORT=3333`
- `DB_HOST`: Cloud SQL socket path
- `DB_DATABASE=cms_production`
- `DB_USER=postgres`
- `DB_PASSWORD`: From secrets
- `STORAGE_BUCKET`: Bucket name
- `GCP_PROJECT_ID`: Project ID

## Manual Deployment

For manual deployment outside of GitHub Actions:

```bash
# Build and push images
gcloud builds submit --tag gcr.io/PROJECT_ID/frontend frontend-app/
gcloud builds submit --tag gcr.io/PROJECT_ID/backend backend-app/

# Deploy services
gcloud run deploy cms-frontend --image gcr.io/PROJECT_ID/frontend
gcloud run deploy cms-backend --image gcr.io/PROJECT_ID/backend
```

## Monitoring & Logs

- **Cloud Run Logs**: `gcloud run services logs tail SERVICE_NAME`
- **Cloud SQL Logs**: Available in GCP Console
- **Storage Access**: Monitor via Cloud Storage logs

## Security Considerations

- Service account has minimal required permissions
- Database uses private IP and Cloud SQL Proxy
- Environment variables stored as GitHub secrets
- HTTPS enforced on all Cloud Run services
- Storage bucket configured for public read access only

## Troubleshooting

### Common Issues

1. **Build failures**: Check environment variables in GitHub secrets
2. **Database connection**: Verify Cloud SQL instance and credentials
3. **Storage issues**: Check bucket permissions and IAM roles
4. **Service deployment**: Review Cloud Run logs for errors

### Useful Commands

```bash
# View service logs
gcloud run services logs tail cms-backend --region us-central1

# Check service status
gcloud run services describe cms-backend --region us-central1

# Access database
gcloud sql connect cms-postgres --user=postgres

# List storage buckets
gsutil ls -b gs://PROJECT_ID-cms-storage
```