terraform {
  cloud {
    organization = "guillaume-neon"
    workspaces {
      name = "pg-dump-restore-infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "pg_dump_restore" {
  name         = "pg-dump-restore"
  force_delete = true
}

output "image_url" {
  value = aws_ecr_repository.pg_dump_restore.repository_url
}
