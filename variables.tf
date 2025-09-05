variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP Zone for resources"
  type        = string
  default     = "us-west1-a"
}

variable "aviatrix_controller_ip" {
  description = "Aviatrix Controller IP Address"
  type        = string
}

variable "aviatrix_username" {
  description = "Aviatrix Controller Username"
  type        = string
}

variable "aviatrix_password" {
  description = "Aviatrix Controller Password"
  type        = string
  sensitive   = true
}

variable "gcp_account_name" {
  description = "Aviatrix GCP Account Name from your Onboarded Account"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "demo"
}