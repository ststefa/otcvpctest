provider "opentelekomcloud" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

locals {
  description = "Will be prefixed to object names"
  project     = "um-vpctest"
}

data "opentelekomcloud_vpc_v1" "vpc" {
  name = "mg-vpctest-vpc"
}

data "opentelekomcloud_vpc_subnet_v1" "subnet_az1" {
  name = "mg-vpctest-subnet-az1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnet_az2" {
  name = "mg-vpctest-subnet-az2"
}
data "opentelekomcloud_networking_network_v2" "net-az1" {
  matching_subnet_cidr = "10.104.199.64/27"
}

data "opentelekomcloud_networking_network_v2" "net-az2" {
  matching_subnet_cidr = "10.104.199.96/27"
}


resource "opentelekomcloud_compute_secgroup_v2" "secgrp" {
  name        = "${local.project}-secgrp"
  description = "${local.project} Security Group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_compute_keypair_v2" "keypair" {
  name       = "${local.project}-key"
  public_key = file("~/keys/tsch-appl_rsa.pub")
}

data "opentelekomcloud_images_image_v2" "osimage" {
  name        = "Standard_CentOS_7_latest"
  most_recent = true
}

resource "opentelekomcloud_compute_instance_v2" "instance" {
  name                = "${local.project}-vm"
  flavor_name         = "s2.medium.4"
  availability_zone   = "eu-ch-02"
  key_pair            = opentelekomcloud_compute_keypair_v2.keypair.id
  security_groups     = [opentelekomcloud_compute_secgroup_v2.secgrp.name]
  stop_before_destroy = true
  auto_recovery       = true

  block_device {
    uuid                  = data.opentelekomcloud_images_image_v2.osimage.id
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    uuid = data.opentelekomcloud_networking_network_v2.net-az2.id
  }
}
