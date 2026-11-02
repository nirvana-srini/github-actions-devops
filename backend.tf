terraform {
  backend "s3" {
    bucket       = "dev-terraform-state-backend-bucket-01112026"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    #dynamodb_table = "dev-terraform-state-lock-table" #LockID partition key
  }
}