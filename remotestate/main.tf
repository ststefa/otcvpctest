provider "opentelekomcloud" {
  domain_name = "tsch_rz_t_001"
  tenant_name = "eu-ch_splunk"
  user_name   = var.username
  password    = var.password
  auth_url    = "https://iam.eu-ch.o13bb.otc.t-systems.com/v3"
}

locals {
  description = "Will be prefixed to object names"
  project     = "rs-vpctest"
}

data "terraform_remote_state" "mg_state" {
  backend = "local"
  config = {
    path = "../managed/terraform.tfstate"
  }
}

resource "opentelekomcloud_compute_instance_v2" "instance" {
  name                = "${local.project}-vm"
  flavor_name         = "s2.medium.4"
  availability_zone   = "eu-ch-02"
  key_pair            = data.terraform_remote_state.mg_state.outputs["keypair_id"]
  security_groups     = [data.terraform_remote_state.mg_state.outputs["secgroup_id"]]
  stop_before_destroy = true
  auto_recovery       = true

  block_device {
    uuid                  = data.terraform_remote_state.mg_state.outputs["osimage_id"]
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    uuid = data.terraform_remote_state.mg_state.outputs["net-az2_id"]
  }
}
