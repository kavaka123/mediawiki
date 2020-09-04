terraform {
    required_version = ">= 0.12.24"
    required_providers {
    aws = {
      version = ">= 3.4.0"
      source = "hashicorp/aws"
    }
  }
}