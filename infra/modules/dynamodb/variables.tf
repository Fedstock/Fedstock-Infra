variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
