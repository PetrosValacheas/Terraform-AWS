
variable "layers_path" {
  type        = string
  description = "Path to directory containing Lambda layers"
}

variable "lambdas_path" {
  type        = string
  description = "Path to directory containing Lambda functions"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}