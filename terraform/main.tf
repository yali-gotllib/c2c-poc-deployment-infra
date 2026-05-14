terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "app" {
  name         = "${var.prefix}-app"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.prefix}-app"
  retention_in_days = 7

  tags = var.tags
}
