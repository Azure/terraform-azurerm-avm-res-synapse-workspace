
variable "sql_administrator_login" {
  type        = string
  default     = "SQLAdmin"
  description = "Specifies The login name of the SQL administrator. Changing this forces a new resource to be created. If this is not provided customer_managed_key must be provided. "
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "The map of tags to be applied to the resource"
}
