
resource "aws_athena_database" "example_database" {
  name = "park_energy_data"
  location_uri  = "s3://energy-production-athena/query-results/"
}


locals {
  park_data = {
    "bemmel"            = "s3://energy-parks-data/bemmel/",
    "netterden"         = "s3://energy-parks-data/netterden/",
    "zwartenbergseweg"  = "s3://energy-parks-data/zwartenbergseweg/",
    "windskanaal"       = "s3://energy-parks-data/windskanaal/",
    "stadskanaal"       = "s3://energy-parks-data/stadskanaal/"
  }
}

resource "aws_athena_named_query" "park_data_query" {
  for_each = local.park_data

  database = aws_athena_database.example_database.name
  name     = "park_energy_data.${each.key}"
  query    = <<QUERY
CREATE EXTERNAL TABLE ${each.key} (
  timestamp timestamp,
  energy_value float
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION '${each.value}'
TBLPROPERTIES ('skip.header.line.count'='1')
QUERY
}