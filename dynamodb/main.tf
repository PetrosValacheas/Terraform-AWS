
resource "aws_dynamodb_table" "Parks-table" {
  name         = "Parks"
  billing_mode = "PAY_PER_REQUEST"
  read_capacity     = 0
  write_capacity    = 0

  hash_key          =  "park_id"
  range_key         =  "energy_type"


  attribute {
    name = "park_id"
    type = "S"
  }
  attribute {
    name = "energy_type"
    type = "S"
  }
}