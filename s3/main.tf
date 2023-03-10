
resource "aws_s3_bucket" "energy-parks-data" {
  bucket = "energy-parks-data"
  tags = {
    Environment = "production"
  }
}


resource "aws_s3_bucket" "energy-production-athena" {
  bucket = "energy-production-athena"
  tags = {
    Environment = "production"
  }
}