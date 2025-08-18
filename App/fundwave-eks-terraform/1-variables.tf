variable "iam_role_attach_cni_policy" {
    default = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    name = local.name
  }
}
