terraform {
  cloud {
    organization = "guillaume-neon"
    workspaces {
      name = "pg-dump-restore-function"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "tfe_outputs" "infra" {
  organization = "guillaume-neon"
  workspace    = "pg-dump-restore-infra"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "pg_dump_restore_lambda" {
  description        = "Role for pg_dump_restore lambda function"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "random_id" "function_name_id" {
  byte_length = 8
}

resource "aws_lambda_function" "pg_dump_restore" {
  function_name = "pg-dump-restore-${random_id.function_name_id.b64_url}"
  role          = aws_iam_role.pg_dump_restore_lambda.arn
  package_type  = "Image"
  image_uri     = "${data.tfe_outputs.infra.nonsensitive_values.image_url}:latest"
  timeout       = 900
}

resource "aws_iam_user" "instagres_webapp" {
  name = "instagres_webapp"
}

data "aws_iam_policy_document" "instagres_webapp" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.pg_dump_restore.arn]
  }
}

resource "aws_iam_user_policy" "instagres_webapp" {
  user   = aws_iam_user.instagres_webapp.name
  policy = data.aws_iam_policy_document.instagres_webapp.json
}

resource "aws_iam_access_key" "instagres_webapp" {
  user = aws_iam_user.instagres_webapp.name
}

output "instagres_webapp_access_key_id" {
  value     = aws_iam_access_key.instagres_webapp.id
  sensitive = true
}

output "instagres_webapp_secret_access_key" {
  value     = aws_iam_access_key.instagres_webapp.secret
  sensitive = true
}

output "function_name" {
  value = aws_lambda_function.pg_dump_restore.function_name
}
