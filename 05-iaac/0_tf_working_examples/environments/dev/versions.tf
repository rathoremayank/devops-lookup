terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 Backend for Remote State Management with DynamoDB Locking
  # 
  # Prerequisites:
  # 1. Run: bash ../../scripts/setup-remote-state.sh
  # 2. This will create S3 bucket and DynamoDB table
  # 3. Update backend-dev.tfbackend with your bucket and table names
  # 4. Run: terraform init -backend-config=backend-dev.tfbackend
  #
  # For more details, see: BACKEND_SETUP.md
  
  backend "s3" {
    # S3 bucket for storing Terraform state
    # Set via -backend-config or in backend-dev.tfbackend
    # bucket = "terraform-state-dev-xyz"
    
    # Path within the bucket (allows multiple projects/environments)
    # set via -backend-config or in backend-dev.tfbackend
    # key = "k8s-cluster/dev/terraform.tfstate"
    
    # AWS region
    # set via -backend-config or in backend-dev.tfbackend
    # region = "us-east-1"
    
    # Enable server-side encryption
    # set via -backend-config or in backend-dev.tfbackend
    # encrypt = true
    
    # DynamoDB table for state locking
    # set via -backend-config or in backend-dev.tfbackend
    # dynamodb_table = "terraform-locks"
    
    # Skip credential validation (set to false for production)
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
