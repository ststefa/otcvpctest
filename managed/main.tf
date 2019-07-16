provider "openstack" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  cloud       = "otc-sbb-t"
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

provider "opentelekomcloud" {
  domain_name = "tsch_rz_t_001"
  # Error: Unsupported argument. An argument named "cloud" is not expected here.
  #cloud       = "otc-sbb-t"
  # Error: Unsupported argument. An argument named "project_name" is not expected here.
  #project_name = "eu-ch_splunk"
  tenant_name = "eu-ch_splunk"
  #user_name   = "ssteine2"
  #password    = "4w8puELDteCC"
  user_name   = "ssteine2-admin"
  password    = "R{DaM$h3bJBN7CPxDK"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
  #delegated_project = "splunk"
}

provider "opentelekomcloud" {
  alias = "root"
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch"
  user_name   = "ssteine2-admin"
  password    = "R{DaM$h3bJBN7CPxDK"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}


locals {
  description = "Will be prefixed to object names"
  project     = "vpctest"
}

# Error: Error creating OpenStack identity client: No suitable endpoint could be found in the service catalog.
#data "opentelekomcloud_identity_project_v3" "prj" {
#  name = "splunk"
#}

data "openstack_compute_availability_zones_v2" "zones" {
}

data "openstack_networking_network_v2" "extnet" {
  name = "admin_external_net"
}

resource "openstack_compute_instance_v2" "provtest" {
  availability_zone = "eu-ch-01"
  flavor_name       = "s2.medium.4"
  name              = "${local.project}-vm"
  key_pair          = openstack_compute_keypair_v2.keypair.id
  image_name        = "Standard_CentOS_7_latest"

  security_groups = [openstack_compute_secgroup_v2.secgrp.name]

  network {
    uuid = opentelekomcloud_vpc_subnet_v1.subnet-az1.id
  }

}

# Error: Your query returned no results. Please change your search criteria and try again.
data "opentelekomcloud_vpc_v1" "vpc_hub" {
  provider = "opentelekomcloud.root"
  name   = "TSCH_RZ_T_HUB"
  #region = "eu-ch"
}

resource "opentelekomcloud_vpc_v1" "vpc" {
  cidr   = "10.104.199.64/26"
  name   = "${local.project}-vpc"
  #region = "eu-ch"
}

resource "opentelekomcloud_vpc_peering_connection_v2" "vpc_peering" {
  name        = "${opentelekomcloud_vpc_v1.vpc.name}-peering"
  vpc_id      = opentelekomcloud_vpc_v1.vpc.id
  peer_tenant_id = "b836871e5ec04d1b8edcef60c49b9bb6" # tsch_rz_t_001
  #peer_vpc_id = "${data.opentelekomcloud_vpc_v1.vpc_hub.id}"
  #peer_vpc_id = "a410c562-4103-4e87-ae61-186a2e1be52c" #TSCH_RZ_P_HUB_01
  peer_vpc_id = "${data.opentelekomcloud_vpc_v1.vpc_hub.id}" # "c13d2fa9-aa8f-4cab-94b0-634093d1d791"
}

resource "opentelekomcloud_vpc_peering_connection_accepter_v2" "accepter" {
  provider = "opentelekomcloud.root"
  vpc_peering_connection_id = opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id
  accept = true
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

resource "opentelekomcloud_vpc_route_v2" "vpc_peering_route_local" {
  #region      = "eu-ch"
  type        = "peering"
  nexthop     = "${opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id}"
  destination = "0.0.0.0/0"
  vpc_id      = opentelekomcloud_vpc_v1.vpc.id
  depends_on = [opentelekomcloud_vpc_peering_connection_accepter_v2.accepter]
}

resource "opentelekomcloud_vpc_route_v2" "vpc_peering_route_peer" {
  provider = "opentelekomcloud.root"
  #region      = "eu-ch"
  type        = "peering"
  nexthop     = "${opentelekomcloud_vpc_peering_connection_v2.vpc_peering.id}"
  destination = "10.104.199.64/26"
  vpc_id      = data.opentelekomcloud_vpc_v1.vpc_hub.id
  depends_on = [opentelekomcloud_vpc_peering_connection_accepter_v2.accepter]
}

resource "opentelekomcloud_vpc_subnet_v1" "subnet-az1" {
  name              = "${local.project}-subnet-az1"
  #region            = "eu-ch"
  cidr              = "10.104.199.64/27"
  gateway_ip        = "10.104.199.65"
  vpc_id            = opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-01"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}

resource "opentelekomcloud_vpc_subnet_v1" "subnet-az2" {
  name              = "${local.project}-subnet-az2"
  #region            = "eu-ch"
  cidr              = "10.104.199.96/27"
  gateway_ip        = "10.104.199.97"
  vpc_id            = opentelekomcloud_vpc_v1.vpc.id
  availability_zone = "eu-ch-02"
  primary_dns       = "100.125.4.25"
  secondary_dns     = "100.125.0.43"
}

#resource "opentelekomcloud_networking_router_v2" "router" {
#  name             = "${local.project}-router"
#  external_gateway = data.openstack_networking_network_v2.extnet.id
#}

resource "openstack_compute_secgroup_v2" "secgrp" {
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

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${local.project}-key"
  public_key = file("~/keys/tsch-appl_rsa.pub")
}

output "ip-address" {
  description = "list of ipv4 addresses of all servers"
  value       = openstack_compute_instance_v2.provtest.access_ip_v4
}

output "id" {
  description = "ID of server"
  value       = openstack_compute_instance_v2.provtest.id
}
