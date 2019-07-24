output "ip-address" {
  description = "ip of server"
  value       = opentelekomcloud_compute_instance_v2.instance.access_ip_v4
}

output "id" {
  description = "ID of server"
  value       = opentelekomcloud_compute_instance_v2.instance.id
}
