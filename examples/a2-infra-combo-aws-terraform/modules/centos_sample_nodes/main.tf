# This module is responsible for setting up any sample nodes running CentOS.

# Find the most recent CentOS 7 AMI
data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["chef-highperf-centos7-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["446539779517"]
}

# Spin up the sample node
resource "aws_instance" "centos_sample_node" {
  ami           = "${data.aws_ami.centos.id}"
  count         = "${var.node_count}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  security_groups = ["${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"]
  tags = "${merge(
  var.common_tags,
  map(
    "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_centos_sample_node_${count.index + 1}",
    "X-Role", "CentOS Sample Node ${count.index + 1}"
    )
  )}"
}

# CentOS sample nodes DNS entry
resource "aws_route53_record" "centos_sample_node" {
  zone_id = "${var.domain_zone_id}"
  count   = "${var.node_count}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-centos-sample-${count.index + 1}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.centos_sample_node[count.index].public_ip}"]
}
