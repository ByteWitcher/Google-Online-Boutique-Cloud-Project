variable "project" {
  type    = string
  default = "cloud-k8s-project-478207"
}

variable "region" {
  type    = string
  default = "europe-west6"
}

variable "zone" {
  type    = string
  default = "europe-west6-a"
}

variable "instance_name" {
  type    = string
  default = "loadgenerator-vm"
}

variable "frontend_ip" {
  type = string
}

variable "users" {
  type    = number
  default = 10
}

variable "run_time" {
  type    = string
  default = "5m"
}