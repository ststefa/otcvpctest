provider "opentelekomcloud" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "opentelekomcloud" {
  alias       = "root"
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch"
  user_name   = var.username
  password    = var.password
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

locals {
  description = "Will be prefixed to object names"
  project     = "vpctest"
}

data "opentelekomcloud_vpc_v1" "vpc_hub" {
  provider = "opentelekomcloud.root"
  name     = "TSCH_RZ_T_HUB"
}

resource "opentelekomcloud_vpc_v1" "vpc" {
  cidr = "10.104.199.64/26"
  name = "${local.project}-vpc"
}

resource "opentelekomcloud_vpc_peering_connection_v2" "vpc_peering" {
  name           = "${opentelekomcloud_vpc_v1.vpc.name}-peering"
  vpc_id         = opentelekomcloud_vpc_v1.vpc.id
  peer_tenant_id = "b836871e5ec04d1b8edcef60c49b9bb6"           # tsch_rz_t_001
  peer_vpc_id    = "${data.opentelekomcloud_vpc_v1.vpc_hub.id}" # "c13d2fa9-aa8f-4cab-94b0-634093d1d791"
}

resource "opentelekomcloud_vpc_peering_connection_accepter_v2" "accepter" {
  provider                  = "opentelekomcloud.root"
  vpc_peering_connection_id = opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id
  accept                    = true
}

# reverse direction, fails
#resource "opentelekomcloud_vpc_peering_connection_v2" "vpc_peering" {
#  provider = "opentelekomcloud.root"
#  name        = "${opentelekomcloud_vpc_v1.vpc.name}-peering"
#  vpc_id      = "${data.opentelekomcloud_vpc_v1.vpc_hub.id}"
#  #peer_vpc_id = "${data.opentelekomcloud_vpc_v1.vpc_hub.id}"
#  #peer_vpc_id = "a410c562-4103-4e87-ae61-186a2e1be52c" #TSCH_RZ_P_HUB_01
#  peer_vpc_id = "${opentelekomcloud_vpc_v1.vpc.id}"
#}
#
#resource "opentelekomcloud_vpc_peering_connection_accepter_v2" "accepter" {
#  vpc_peering_connection_id = opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id
#  accept = true
#}

resource "opentelekomcloud_vpc_route_v2" "route_local" {
  type        = "peering"
  nexthop     = "${opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id}"
  destination = "0.0.0.0/0"
  vpc_id      = opentelekomcloud_vpc_v1.vpc.id
  depends_on  = [opentelekomcloud_vpc_peering_connection_accepter_v2.accepter]
}

resource "opentelekomcloud_vpc_route_v2" "route_peer" {
  provider    = "opentelekomcloud.root"
  type        = "peering"
  nexthop     = "${opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id}"
  destination = "10.104.199.64/26"
  vpc_id      = data.opentelekomcloud_vpc_v1.vpc_hub.id
  depends_on  = [opentelekomcloud_vpc_peering_connection_accepter_v2.accepter]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnet-az1" {
  name              = "${local.project}-subnet-az1"
  cidr              = "10.104.199.64/27"
  gateway_ip        = "10.104.199.65"
  vpc_id            = opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-01"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}

resource "opentelekomcloud_vpc_subnet_v1" "subnet-az2" {
  name              = "${local.project}-subnet-az2"
  cidr              = "10.104.199.96/27"
  gateway_ip        = "10.104.199.97"
  vpc_id            = opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-02"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}


data "opentelekomcloud_networking_network_v2" "net-az1" {
  matching_subnet_cidr = "10.104.199.64/27"
  # The dependency (although correct) leads to VM recreation on every apply
  #depends_on           = [opentelekomcloud_vpc_subnet_v1.subnet-az1]
}

data "opentelekomcloud_networking_network_v2" "net-az2" {
  matching_subnet_cidr = "10.104.199.96/27"
  #depends_on           = [opentelekomcloud_vpc_subnet_v1.subnet-az2]
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
  name              = "${local.project}-vm"
  flavor_name       = "s2.medium.4"
  availability_zone = "eu-ch-01"
  key_pair          = opentelekomcloud_compute_keypair_v2.keypair.id
  security_groups = [
  opentelekomcloud_compute_secgroup_v2.secgrp.name]
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
    uuid = data.opentelekomcloud_networking_network_v2.net-az1.id
  }
}

output "ip-address" {
  description = "ip of server"
  value       = opentelekomcloud_compute_instance_v2.instance.access_ip_v4
}

output "id" {
  description = "ID of server"
  value       = opentelekomcloud_compute_instance_v2.instance.id
}
