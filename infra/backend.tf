terraform {
  backend "s3" {
    bucket         = "pb-test-tf"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "pb-test-tf"
  }
}
