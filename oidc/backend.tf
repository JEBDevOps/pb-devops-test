terraform {
  backend "s3" {
    bucket         = "pb-test-tf"
    key            = "oidc-terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "oidc-pb-test-tf"
  }
}
