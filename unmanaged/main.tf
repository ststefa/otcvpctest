/*

We use VPCs to organize the network. A VPC conists of the VPC itself, implicit
networks (i.e. created by the webgui "under the hood") and explicit subnets.
This makes network names unusable (i.e. non-unique):

$ openstack --os-cloud otc-sbb-t network list
+--------------------------------------+--------------------------------------+--------------------------------------+
| ID                                   | Name                                 | Subnets                              |
+--------------------------------------+--------------------------------------+--------------------------------------+
| 0c7192a0-b7a0-498a-a317-c788a27f71be | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | 8f4f6547-4152-4d4a-bb49-cd3ef855b098 |
| 25081612-36c2-4ea5-ad1f-ece095f9be8e | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | d5b8fc09-a066-419b-80a9-a22b1f71a0bc |
| 8b0e7640-8b67-4c8e-9934-bf46c2a987f6 | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | f132f729-1f9a-40ea-aefc-aa2d87163e28 |
| b6930a97-17d2-435c-8610-694a41451ab5 | d7eb20f7-a98d-4616-95f9-d89ef6b0a114 | b3eb7367-0db3-42b6-a062-676e57b3face |
| 0a2228f2-7f8a-45f1-8e09-9039e1d09975 | admin_external_net                   |                                      |
+--------------------------------------+--------------------------------------+--------------------------------------+

However we need to reference the network in several places like e.g. the ECS
network config. It is unreadable to reference them by id. We could reference
by cidr but that's also confusing. Therefor we rename them in analogy to the
subnets to make them easier to reference:

$ openstack --os-cloud otc-sbb-t subnet list
+--------------------------------------+---------------------+--------------------------------------+-------------------+
| ID                                   | Name                | Network                              | Subnet            |
+--------------------------------------+---------------------+--------------------------------------+-------------------+
| 8f4f6547-4152-4d4a-bb49-cd3ef855b098 | splunk-subnet-az1-2 | 0c7192a0-b7a0-498a-a317-c788a27f71be | 10.104.198.224/28 |
| b3eb7367-0db3-42b6-a062-676e57b3face | splunk-subnet-az2-1 | b6930a97-17d2-435c-8610-694a41451ab5 | 10.104.198.208/28 |
| d5b8fc09-a066-419b-80a9-a22b1f71a0bc | splunk-subnet-az1-1 | 25081612-36c2-4ea5-ad1f-ece095f9be8e | 10.104.198.192/28 |
| f132f729-1f9a-40ea-aefc-aa2d87163e28 | splunk-subnet-az2-2 | 8b0e7640-8b67-4c8e-9934-bf46c2a987f6 | 10.104.198.240/28 |
+--------------------------------------+---------------------+--------------------------------------+-------------------+

$ openstack --os-cloud otc-sbb-t network set --name splunk-net-az1-1 25081612-36c2-4ea5-ad1f-ece095f9be8e
$ openstack --os-cloud otc-sbb-t network set --name splunk-net-az2-1 b6930a97-17d2-435c-8610-694a41451ab5
$ openstack --os-cloud otc-sbb-t network set --name splunk-net-az1-2 0c7192a0-b7a0-498a-a317-c788a27f71be
$ openstack --os-cloud otc-sbb-t network set --name splunk-net-az2-2 8b0e7640-8b67-4c8e-9934-bf46c2a987f6

$ openstack --os-cloud otc-sbb-t network list
+--------------------------------------+--------------------+--------------------------------------+
| ID                                   | Name               | Subnets                              |
+--------------------------------------+--------------------+--------------------------------------+
| 0c7192a0-b7a0-498a-a317-c788a27f71be | splunk-net-az1-2   | 8f4f6547-4152-4d4a-bb49-cd3ef855b098 |
| 25081612-36c2-4ea5-ad1f-ece095f9be8e | splunk-net-az1-1   | d5b8fc09-a066-419b-80a9-a22b1f71a0bc |
| 8b0e7640-8b67-4c8e-9934-bf46c2a987f6 | splunk-net-az2-2   | f132f729-1f9a-40ea-aefc-aa2d87163e28 |
| b6930a97-17d2-435c-8610-694a41451ab5 | splunk-net-az2-1   | b3eb7367-0db3-42b6-a062-676e57b3face |
| 0a2228f2-7f8a-45f1-8e09-9039e1d09975 | admin_external_net |                                      |
+--------------------------------------+--------------------+--------------------------------------+

We can now refer to the networks by name (e.g. "splunk-net-az1-1"

*/

provider "opentelekomcloud" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  user_name   = "john"
  password    = "*****"
  auth_url = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

locals {
  description = "Will be prefixed to object names"
  project     = "um-vpctest"
}

data "opentelekomcloud_vpc_v1" "vpc" {
  name = "splunk-vpc"
}

data "opentelekomcloud_networking_network_v2" "net-az1" {
  name = "splunk-net-az1-1"
}

data "opentelekomcloud_networking_network_v2" "net-az2" {
  name = "splunk-subnet-az2-1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnet_az1" {
  vpc_id = data.opentelekomcloud_vpc_v1.vpc.id
  name = "splunk-subnet-az1-1"
}

data "opentelekomcloud_vpc_subnet_v1" "subnet_az2" {
  vpc_id = data.opentelekomcloud_vpc_v1.vpc.id
  name = "splunk-subnet-az1-2"
}

resource "opentelekomcloud_compute_instance_v2" "instance" {
  name            = "${local.project}-vm"
  flavor_name       = "s2.medium.4"
  key_pair          = opentelekomcloud_compute_keypair_v2.keypair.id
  security_groups = [opentelekomcloud_compute_secgroup_v2.secgrp.name]
  stop_before_destroy = true
  auto_recovery = true

  block_device {
    image_name            = "Standard_CentOS_7_latest"
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
    volume_type = "SAS" # SSD|SAS
  }

  network {
    uuid = data.opentelekomcloud_networking_network_v2.net-az1.id
    fixed_ip_v4 = "10.104.198.194"
    access_network = true
  }
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

output "ip-address" {
  description = "list of ipv4 addresses of all servers"
  value       = opentelekomcloud_compute_instance_v2.instance.access_ip_v4
}

output "id" {
  description = "ID of server"
  value       = opentelekomcloud_compute_instance_v2.instance.id
}
