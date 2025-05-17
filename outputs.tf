# output "instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.app_server.id
# }
#
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value = {
    for instance_key, instance in aws_instance.app_ec2_instances :
    instance_key => "https://${instance.public_ip}:443/ejbca/adminweb/"
  }
}
output "database_endpoint" {
  description = "the maria db endpoint that needs to be passed to the ejbca container"
  value       = aws_db_instance.ejbca.endpoint
}
