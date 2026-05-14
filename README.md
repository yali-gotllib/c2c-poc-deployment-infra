# C2C PoC Deployment Infrastructure

This repository contains Terraform code for deploying the Wiz C2C (Cloud-to-Cloud) Proof of Concept infrastructure to AWS.

## Overview

This infrastructure repository works in conjunction with the Dockerfile templates repository to deploy containerized applications to AWS.

## Related Repositories

- **Dockerfile Templates**: [https://github.com/yali-gotllib/c2c-poc-dockerfile-templates](https://github.com/yali-gotllib/c2c-poc-dockerfile-templates)
  - Contains Dockerfile templates referenced by the Terraform configurations in this repository

## AWS Configuration

- **Region**: us-east-1

## Structure

```
.
├── README.md
├── main.tf           # Main Terraform configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output definitions
└── modules/          # Terraform modules
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Access to the Dockerfile templates repository

## Usage

1. Clone this repository
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review the execution plan:
   ```bash
   terraform plan
   ```
4. Apply the configuration:
   ```bash
   terraform apply
   ```

## License

Proprietary - Internal use only
