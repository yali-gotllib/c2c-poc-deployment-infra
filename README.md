# C2C PoC Deployment Infrastructure

This repository contains Terraform code for deploying the Wiz C2C (Cloud-to-Cloud) Proof of Concept infrastructure to AWS ECS.

## Overview

This infrastructure repository demonstrates a cross-repository deployment pattern where:
- **Dockerfile source**: Fetched from the templates repository (NOT in this repo)
- **Infrastructure as Code**: Terraform configurations in this repository
- **Runtime**: AWS ECS Fargate

This pattern intentionally breaks the default C2C correlation since the Dockerfile is external.

## Related Repositories

- **Dockerfile Templates**: [https://github.com/yali-gotllib/c2c-poc-dockerfile-templates](https://github.com/yali-gotllib/c2c-poc-dockerfile-templates)
  - Contains Dockerfile templates at `templates/app/Dockerfile`
  - Referenced by the build-and-deploy script

## AWS Configuration

- **Region**: us-east-1
- **Account ID**: 990976650592

## Architecture

```
+-------------------------+       +---------------------------+
| c2c-poc-dockerfile-     |       | c2c-poc-deployment-infra  |
| templates (this repo)   |       | (Terraform + Deploy)      |
+-------------------------+       +---------------------------+
| templates/app/Dockerfile| <---- | build-and-deploy.sh       |
+-------------------------+       |   - Clones templates repo |
                                  |   - Builds Docker image   |
                                  |   - Pushes to ECR         |
                                  |   - Updates ECS service   |
                                  +---------------------------+
                                             |
                                             v
                                  +---------------------------+
                                  | AWS Infrastructure        |
                                  |   - ECR Repository        |
                                  |   - ECS Cluster (Fargate) |
                                  |   - VPC with 2 subnets    |
                                  |   - CloudWatch Logs       |
                                  +---------------------------+
```

## Repository Structure

```
.
├── README.md
└── terraform/
    ├── main.tf              # Provider config, ECR, CloudWatch
    ├── vpc.tf               # VPC, subnets, security groups
    ├── ecs.tf               # ECS cluster, task definition, service
    ├── variables.tf         # Input variables
    ├── outputs.tf           # Output definitions
    └── build-and-deploy.sh  # Build and deploy script
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Docker installed and running
- Access to the Dockerfile templates repository

## Usage

### 1. Initialize and Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

### 2. Build and Deploy Application

After the infrastructure is created, use the build-and-deploy script:

```bash
cd terraform

# Set environment variables (optional - defaults shown)
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=990976650592
export PREFIX=c2c-poc
export IMAGE_TAG=latest

# Run the build and deploy script
./build-and-deploy.sh
```

The script will:
1. Clone the Dockerfile templates repository
2. Build the Docker image using `templates/app/Dockerfile`
3. Push the image to ECR
4. Trigger a new ECS deployment

### 3. Monitor Deployment

```bash
# Check service status
aws ecs describe-services \
  --cluster c2c-poc-cluster \
  --services c2c-poc-app-service \
  --region us-east-1

# View logs
aws logs tail /ecs/c2c-poc-app --follow --region us-east-1
```

## Resources Created

| Resource | Name | Description |
|----------|------|-------------|
| ECR Repository | c2c-poc-app | Container image registry |
| ECS Cluster | c2c-poc-cluster | Fargate cluster |
| ECS Service | c2c-poc-app-service | Application service |
| VPC | c2c-poc-vpc | Virtual private cloud |
| Subnets | c2c-poc-public-a/b | Public subnets in 2 AZs |
| Security Group | c2c-poc-ecs-tasks-sg | ECS task networking |
| CloudWatch Log Group | /ecs/c2c-poc-app | Application logs |
| IAM Roles | c2c-poc-ecs-task-* | Task execution and runtime roles |

## Variables

| Name | Description | Default |
|------|-------------|---------|
| aws_region | AWS region | us-east-1 |
| prefix | Resource name prefix | c2c-poc |
| tags | Resource tags | Project=c2c-poc, Environment=production |

## Outputs

| Name | Description |
|------|-------------|
| ecr_repository_url | ECR repository URL for pushing images |
| ecs_cluster_name | ECS cluster name |
| ecs_service_name | ECS service name |
| vpc_id | VPC identifier |
| public_subnet_ids | List of public subnet IDs |

## Security Notes

- The Dockerfile is fetched from an external repository at build time
- ECR image scanning is enabled on push
- ECS tasks run in public subnets with security group controls
- CloudWatch Container Insights is enabled for monitoring

## License

Proprietary - Internal use only
