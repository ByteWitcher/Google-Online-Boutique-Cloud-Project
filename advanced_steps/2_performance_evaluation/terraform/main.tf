provider "google" {
  credentials = "${file("credentials/shopapp-terraform-account.json")}"
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_instance" "vm_instance_master" {

  name = "${var.instance_name}-master"

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

  # Clone project
  cd /tmp
  git clone --depth 1 --branch v0 https://github.com/GoogleCloudPlatform/microservices-demo.git
  cd microservices-demo/src/loadgenerator

  # Modify the Dockerfile to remove the platform argument for compatibility 
  sed -i 's/--platform=\$BUILDPLATFORM //' Dockerfile

  # Modify ENTRYPOINT to use environment variables
  sed -i '/^ENTRYPOINT /d' Dockerfile

  cat <<'EOF' >> Dockerfile
  ENTRYPOINT locust --master --host="http://$${FRONTEND_ADDR}" --headless -u "$${USERS:-10}" -r "$${RATE:-1}" -t "$${RUN_TIME:-5m}" --csv /tmp/results/locust_$${USERS:-10}
  EOF

  mkdir -p /tmp/results

  # Build and run container
  docker build -t loadgenerator .
  docker run --name locust-master --rm -p 5557:5557 -e FRONTEND_ADDR=${var.frontend_ip} -e USERS=${var.users} -e RATE=${var.rate} -e RUN_TIME=${var.run_time} -v /tmp/results:/tmp/results loadgenerator &> /tmp/docker-output.txt
  EOT

}

resource "google_compute_instance" "vm_instance_worker" {

  count = var.num_workers

  name  = "${var.instance_name}-worker-${count.index+1}"

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

  # Clone project
  cd /tmp
  git clone --depth 1 --branch v0 https://github.com/GoogleCloudPlatform/microservices-demo.git
  cd microservices-demo/src/loadgenerator

  # Modify the Dockerfile to remove the platform argument for compatibility 
  sed -i 's/--platform=\$BUILDPLATFORM //' Dockerfile

  # Modify ENTRYPOINT to use environment variables
  sed -i '/^ENTRYPOINT /d' Dockerfile

  cat <<'EOF' >> Dockerfile
  ENTRYPOINT locust --worker --master-host="$${MASTER_IP_ADDRESS}"
  EOF

  mkdir -p /tmp/results

  # Build and run container
  docker build -t loadgenerator .

  MASTER_IP_ADDRESS=${google_compute_instance.vm_instance_master.network_interface[0].network_ip}

  docker run --rm -e MASTER_IP_ADDRESS=$MASTER_IP_ADDRESS loadgenerator &> /tmp/docker-output.txt
  EOT

}