output "centos_sample_nodes" {
  value = aws_route53_record.centos_sample_node.*.fqdn
}
