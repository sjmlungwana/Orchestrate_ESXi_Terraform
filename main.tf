terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.4.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

## Generating keys ##

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyKey.pem"
}

## end keys ##

provider "vsphere" {
  # Configuration options
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
}

data "vsphere_datastore" "datastore" {
  name          = "datastore-test"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "rogan" {
  name          = "datastore2"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = "192.168.26.225"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_vmfs_disks" "vmfs_disks" {
  host_system_id = data.vsphere_host.host.id
  rescan         = true
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "parent" {
  path          = "VMworld"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "web" {
  path          = "${vsphere_folder.parent.path}/web"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "temp" {
  path          = "${vsphere_folder.parent.path}/templates"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "FirstCluster"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "Temp-VM"
  datacenter_id = data.vsphere_datacenter.dc.id
}



resource "vsphere_virtual_machine" "vm" {
  name             = "New-VM"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 1
  memory           = 1024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 20
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

resource "null_resource" "test_provisioner" {
  connection {
    type = "ssh"
    host = "192.168.26.94"
    user = "sps"
    password = var.vsphere_password
  }

  provisioner "local-exec" {
    command = "scp script.sh chronograf_1.10.1_amd64.deb grafana_9.5.3_amd64.deb influxdb_1.8.10_amd64.deb grafana.sh influxdb.sh chronograf.sh sps@192.168.26.94:/home/sps"
  }

  provisioner "remote-exec" {
    inline = [
      "CHRONOGRAF=${var.chronograf}",
      "INFLUX=${var.influx}",
      "GRAFANA=${var.grafana}",
      "chmod 755 /home/sps/script.sh",
      "chmod 755 /home/sps/grafana.sh",
      "chmod 755 /home/sps/influxdb.sh",
      "chmod 755 /home/sps/chronograf.sh",
      "sh /home/sps/script.sh",
    ]
  }
}

# Our Local server for testing, it must have all the necessary packages as if it is my own PC

resource "vsphere_virtual_machine" "local_server" {
  name             = "Local Server"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 40
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

# These are the servers for testing...

resource "vsphere_virtual_machine" "local_host" {
  name             = "Local Host"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

resource "vsphere_virtual_machine" "mivu_server" {
  name             = "Mivu Server"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

################ End of servers for testing ####################

#  start salt master and minion testing #

resource "vsphere_virtual_machine" "salt_master" {
  name             = "Salt Master"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  extra_config = {
    cloud-init = file("cloud-init-config.yaml")
    command = "touch system.txt"
  }
}

resource "vsphere_virtual_machine" "salt_minion" {
  name             = "Salt Minion"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}


################ Prometheus ####################

resource "vsphere_virtual_machine" "Prometheus" {
  name             = "Prometheus"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

################ OpenVPN Server ####################

resource "vsphere_virtual_machine" "openvpn-server" {
  name             = "OpenVPN"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}

################ Code-Server ####################

resource "vsphere_virtual_machine" "code-server" {
  name             = "code-server"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.rogan.id
  num_cpus         = 1
  memory           = 2024
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 50
  }
  lifecycle {
    ignore_changes = [disk]
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}
