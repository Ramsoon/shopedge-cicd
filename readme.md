# ShopEdge CI/CD Pipeline on GCP

A complete CI/CD pipeline for ShopEdge application using GCP, GitHub Actions, Jenkins, and Kubernetes.

## Architecture

1. **Infrastructure as Code**: Terraform provisions GKE cluster and Artifact Registry
2. **CI Pipeline**: GitHub Actions builds and pushes Docker images
3. **CD Pipeline**: Jenkins deploys to GKE and manages releases
4. **Monitoring**: Prometheus and Grafana for observability

## Setup Instructions

### Prerequisites
- GCP account with billing enabled
- GitHub repository
- Jenkins instance

### 1. Infrastructure Setup
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh