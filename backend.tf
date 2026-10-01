terraform {
  backend "s3" {
    bucket       = "ts-academy-statefile"
    key          = "tf-academy.tfstate"
    region       = "us-east-1"
  }
}


