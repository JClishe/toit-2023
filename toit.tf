# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration
variable "instance_count" { default = 3 }
variable "prefix_moniker" { default = "toit" }
variable "zone" { default = "us-east5-a" }

locals {
  region = replace(var.zone, "/-[a-z]$/", "") #
  names  = [for i in range(var.instance_count) : "${var.prefix_moniker}-${100 + i}"]
  #names = [ "${var.prefix_moniker}-${100+0}", "${var.prefix_moniker}-${100+2}"] #if we wanted to DESTROY specific VM's AFTER this code had been applied, we can replace the "names" variable with a list of the specific VM's we wanted to keep 
}
output "locals" {
  value = {
    region = local.region,
    names  = local.names
  }
}

resource "google_compute_instance" "instances_foreachloop" {
  # Creates the specified number of VM's per "instance_count" variable using a for_each loop
  for_each = toset(local.names)

  boot_disk {
    auto_delete = true
    device_name = each.value

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-11-bullseye-v20231010"
      size  = 10
      type  = "pd-balanced"
      labels = {
        goog-ec-src = "vm_add-tf",
        name        = each.value
      }
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf",
    name        = each.value
  }

  machine_type = "e2-small"
  name         = each.value

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    subnetwork = "projects/jclishe-sandbox/regions/${local.region}/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "420825106848-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone = var.zone
}

/*
resource "google_compute_instance" "instances_instancecount" {
  # Creates the specified number of VM's per "instance_count" variable using a count statement
  count = var.instance_count

  boot_disk {
    auto_delete = true
    device_name = "${var.prefix_moniker}-${200 + count.index}"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-11-bullseye-v20231010"
      size  = 10
      type  = "pd-balanced"
      labels = {
        goog-ec-src = "vm_add-tf",
        name        = "${var.prefix_moniker}-${200 + count.index}"
      }
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf",
    name        = "${var.prefix_moniker}-${200 + count.index}"
  }

  machine_type = "e2-small"
  name         = "${var.prefix_moniker}-${200 + count.index}"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    subnetwork = "projects/jclishe-sandbox/regions/${local.region}/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "420825106848-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone = var.zone
}
*/
