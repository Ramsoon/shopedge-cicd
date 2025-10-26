#!/bin/bash

# Setup script for ShopEdge CI/CD pipeline

set -e

echo "Setting up ShopEdge CI/CD pipeline..."

# Variables
PROJECT_ID="striking-water-472711-g2"
REGION="us-central1"
CLUSTER_NAME="shopedgedge-cluster"

# Create GCP project and enable APIs
echo "Creating GCP project and enabling APIs..."
gcloud projects create $PROJECT_ID --name="ShopEdge Project"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
    container.googleapis.com \
    artifactregistry.googleapis.com \
    compute.googleapis.com \
    iam.googleapis.com

# Create infrastructure with Terraform
echo "Creating infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -var="project_id=$PROJECT_ID" -var="region=$REGION" -auto-approve

# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# Create namespaces
kubectl create namespace monitoring

echo "Setup completed successfully!"