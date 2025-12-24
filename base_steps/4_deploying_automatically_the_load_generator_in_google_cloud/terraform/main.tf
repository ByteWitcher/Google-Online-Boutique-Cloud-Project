
provider "google" {
  credentials = "${file("credentials/shopapp-terraform-account.json")}"
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_instance" "vm_instance" {

  name = var.instance_name

  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update

    # Install docker
    apt-get install -y docker.io git
    systemctl start docker
    systemctl enable docker

    # Clone the project and move to the loadgenerator folder
    cd /tmp
    git clone --depth 1 --branch v0 https://github.com/GoogleCloudPlatform/microservices-demo.git
    cd microservices-demo/src/loadgenerator

    # Modify the Dockerfile to remove the platform argument for compatibility 
    sed -i 's/--platform=\$BUILDPLATFORM //' Dockerfile
    
    # Build and run the container
    docker build -t loadgenerator .
    docker run --rm -e FRONTEND_ADDR=${var.frontend_ip} loadgenerator
  EOT
}
