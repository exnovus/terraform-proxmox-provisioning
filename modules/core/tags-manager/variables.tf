variable "name" {
  type        = string
  description = "Name component for the generated id"
}

variable "stage" {
  type        = string
  description = "Environment/stage (dev, qa, admin, prod)"
}

variable "client" {
  type        = string
  description = "Client component for the generated id"
}

variable "delimiter" {
  type        = string
  description = "Delimiter to use when composing id"
  default     = "-"
}

variable "tags" {
  type        = map(any)
  description = "Additional tags to merge with generated core tags"
  default     = {}
}
