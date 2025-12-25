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

variable "num_workers" {
  type    = number
  default = 2
}