# variable "storage_data_lake_gen2_filesystem_name" {
#   type        = string
#   description = "Specifies the name of storage data lake gen2 filesystem resource."
#   default     = "adls_fs"
# }

variable "cmk_enabled" {
  type        = bool
  default     = true
  description = "Flag to enable the customer_managed_key block."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

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
