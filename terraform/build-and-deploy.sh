#!/bin/bash
set -e

# Configuration
TEMPLATES_REPO="https://github.com/yali-gotllib/c2c-poc-dockerfile-templates"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-990976650592}"
PREFIX="${PREFIX:-c2c-poc}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Derived values
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PREFIX}-app"
WORK_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "C2C PoC Build and Deploy Script"
echo "========================================"
echo "Templates Repo: ${TEMPLATES_REPO}"
echo "ECR Repository: ${ECR_REPOSITORY}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Working Directory: ${WORK_DIR}"
echo "========================================"

# Cleanup function
cleanup() {
    echo "Cleaning up temporary directory..."
    rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

# Step 1: Clone the templates repository
echo ""
echo "Step 1: Cloning templates repository..."
git clone --depth 1 "${TEMPLATES_REPO}" "${WORK_DIR}/templates"

# Check if Dockerfile exists
DOCKERFILE_PATH="${WORK_DIR}/templates/templates/app/Dockerfile"
if [ ! -f "${DOCKERFILE_PATH}" ]; then
    echo "ERROR: Dockerfile not found at ${DOCKERFILE_PATH}"
    echo "Checking available files in templates repo..."
    find "${WORK_DIR}/templates" -name "Dockerfile*" -o -name "*.dockerfile" 2>/dev/null || true
    exit 1
fi

echo "Found Dockerfile at: ${DOCKERFILE_PATH}"

# Step 2: Authenticate with ECR
echo ""
echo "Step 2: Authenticating with ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Step 3: Build the Docker image
echo ""
echo "Step 3: Building Docker image..."
docker build \
    -t "${ECR_REPOSITORY}:${IMAGE_TAG}" \
    -f "${DOCKERFILE_PATH}" \
    "${WORK_DIR}/templates/templates/app"

# Also tag with commit SHA if available
if [ -d "${WORK_DIR}/templates/.git" ]; then
    COMMIT_SHA=$(cd "${WORK_DIR}/templates" && git rev-parse --short HEAD)
    docker tag "${ECR_REPOSITORY}:${IMAGE_TAG}" "${ECR_REPOSITORY}:${COMMIT_SHA}"
    echo "Tagged image with commit SHA: ${COMMIT_SHA}"
fi

# Step 4: Push to ECR
echo ""
echo "Step 4: Pushing image to ECR..."
docker push "${ECR_REPOSITORY}:${IMAGE_TAG}"

if [ -n "${COMMIT_SHA}" ]; then
    docker push "${ECR_REPOSITORY}:${COMMIT_SHA}"
fi

# Step 5: Update ECS service
echo ""
echo "Step 5: Updating ECS service..."
ECS_CLUSTER="${PREFIX}-cluster"
ECS_SERVICE="${PREFIX}-app-service"

# Force new deployment to pick up the latest image
aws ecs update-service \
    --cluster "${ECS_CLUSTER}" \
    --service "${ECS_SERVICE}" \
    --force-new-deployment \
    --region "${AWS_REGION}" > /dev/null

echo ""
echo "========================================"
echo "Deployment initiated successfully!"
echo "========================================"
echo "ECR Image: ${ECR_REPOSITORY}:${IMAGE_TAG}"
echo "ECS Cluster: ${ECS_CLUSTER}"
echo "ECS Service: ${ECS_SERVICE}"
echo ""
echo "Monitor deployment with:"
echo "  aws ecs describe-services --cluster ${ECS_CLUSTER} --services ${ECS_SERVICE} --region ${AWS_REGION}"
echo "========================================"
