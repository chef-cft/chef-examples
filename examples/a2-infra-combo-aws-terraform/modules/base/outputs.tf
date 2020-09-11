# Outputs
# Automate Server
output "a2_server_url" {
  value            = "https://${aws_route53_record.a2_server.fqdn}"
}
