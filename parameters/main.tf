

resource "aws_ssm_parameter" "athena_config" {
  name  = "athena_config"
  type  = "String"
  value = jsonencode({
    production = {
      query_statuses = {
        final  = ["SUCCEEDED", "CANCELLED", "FAILED"],
        failed = ["CANCELLED", "FAILED"]
      },
      query_status_poll_interval_seconds = 15,
      max_results = 50,
      database_region = "eu-central-1",
      database = "park_energy_data",
      athena-query-results = "s3://energy-production-athena/"
    }
  })
}