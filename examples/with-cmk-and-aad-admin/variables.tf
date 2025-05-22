variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "storage_data_lake_gen2_filesystem_name" {
  type        = string
  description = "Specifies the name of storage data lake gen2 filesystem resource."
}

variable "sql_administrator_login" {
  type        = string
  default     = "SQLAdmin"
  description = "Specifies The login name of the SQL administrator. Changing this forces a new resource to be created. If this is not provided customer_managed_key must be provided. "
}

variable "sql_administrator_login_password" {
  type        = string
  sensitive   = true
  default     = "null"
  description = "The Password associated with the sql_administrator_login for the SQL administrator. If this is not provided customer_managed_key must be provided."
}

variable "synapse_key_name" {
  description = "The ID of the customer-managed key"
  type        = string
  default     = "enckey"
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "The map of tags to be applied to the resource"
}

