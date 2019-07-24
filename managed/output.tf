output "ip-address" {
  description = "ip of server"
  value       = opentelekomcloud_compute_instance_v2.instance.access_ip_v4
}

output "id" {
  description = "ID of server"
  value       = opentelekomcloud_compute_instance_v2.instance.id
}

output "net-az1_id" {
  value       = data.opentelekomcloud_networking_network_v2.net-az1.id
}
output "net-az2_id" {
  value       = data.opentelekomcloud_networking_network_v2.net-az2.id
}

output "keypair_id" {
  value       = opentelekomcloud_compute_keypair_v2.keypair.id
}

output "secgroup_id" {
  value       = opentelekomcloud_compute_secgroup_v2.secgrp.id
}


output "osimage_id" {
  value       = data.opentelekomcloud_images_image_v2.osimage.id
}
