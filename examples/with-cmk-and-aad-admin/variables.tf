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

variable "key_vault_access_policy_wait_duration" {
  type        = string
  default     = "30s"
  description = "Duration to wait for Key Vault access policy propagation. Set to '0s' to disable waiting. Useful for handling eventual consistency issues with permission propagation. Change to '0s' if you do not need the delay."
  nullable    = false
}
