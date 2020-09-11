# This module is responsible for setting up the Chef Server and the Chef
# Automate 2 server.  Additionally, it generates the necessary API key and
# configuration bits to get them talking to each other.

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

# Create Security Group
resource "aws_security_group" "allow-all" {
  name        = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"
  description = "Allow all inbound/outbound traffic"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

###########
# A2 Server
###########

# A2 server DNS entry
resource "aws_route53_record" "a2_server" {
  zone_id = "${var.domain_zone_id}"
  name    = "${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-automate"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.a2_server.public_ip}"]
}

# Set up A2 license file
data "template_file" "a2_license" {
  template = "${file("${path.module}/files/a2_license.tpl")}"
  vars = {
    content = "${var.a2_license}"
  }
}

# Set up certgen.conf
data "template_file" "a2_server_certgen_conf" {
  template = "${file("${path.module}/files/certgen.conf.tpl")}"
  vars = {
    fqdn = "${aws_route53_record.a2_server.fqdn}"
  }
}

# Spin up the A2 server
resource "aws_instance" "a2_server" {
    ami           = "${data.aws_ami.centos.id}"
    instance_type = "${var.a2_server_instance_type}"
    key_name      = "${var.key_name}"
    security_groups = ["${lookup(var.common_tags, "X-Contact")}-${lookup(var.common_tags, "X-Project")}-allow-all"]
    root_block_device {
      volume_size = "25"
      delete_on_termination = true
    }
    tags = "${merge(
      var.common_tags,
      map(
        "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_a2_server",
        "X-Role", "Chef Server"
      )
    )}"
    volume_tags = "${merge(
      var.common_tags,
      map(
        "Name", "${lookup(var.common_tags, "X-Contact")}_${lookup(var.common_tags, "X-Project")}_a2_server",
        "X-Role", "Chef Server"
      )
    )}"
  }

# Post-provisioning steps for A2 server
resource "null_resource" "a2_preparation" {
  depends_on = [aws_route53_record.a2_server]
    triggers = {
        instance = "${aws_instance.a2_server.id}"
        key = "${uuid()}"
    }

    connection {
      host        ="${aws_instance.a2_server.public_ip}"
      user        = "centos"
      agent       = true
      private_key = "${file("${var.instance_key}")}"
      }

    # Write /tmp/a2_license
    provisioner "file" {
      content     = "${data.template_file.a2_license.rendered}"
      destination = "/tmp/a2_license"
    }

    # Write /tmp/a2_license_apply for conditional license application
    provisioner "file" {
      source      = "${path.module}/files/a2_license_apply.sh"
      destination = "/tmp/a2_license_apply.sh"
    }

    # Write /tmp/download_compliance_profiles.sh
    provisioner "file" {
      source      = "${path.module}/files/download_compliance_profiles.sh"
      destination = "/tmp/download_compliance_profiles.sh"
    }

    # Write certgen.conf
    provisioner "file" {
      content        = "${data.template_file.a2_server_certgen_conf.rendered}"
      destination    = "/tmp/certgen.conf"
    }

    # Install Automate 2
    provisioner "remote-exec" {
      inline = [
        "sudo yum install -y epel-release",
        "sudo yum install -y jq",
        "sudo mkdir /opt/chef-ssl && sudo chmod 755 /opt/chef-ssl",
        "cd /opt/chef-ssl",
        "sudo openssl req -new -x509 -nodes -keyout a2_server.key -out a2_server.pem -config /tmp/certgen.conf",
        "sudo chmod 600 /opt/chef-ssl/a2_server.pem /opt/chef-ssl/a2_server.key",
        "cd /tmp",
        "curl -s https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate",
        "sudo ./chef-automate init-config --fqdn ${aws_route53_record.a2_server.fqdn} --certificate /opt/chef-ssl/a2_server.pem --private-key /opt/chef-ssl/a2_server.key",
        "sudo /usr/sbin/sysctl -w vm.max_map_count=262144",
        "sudo /usr/sbin/sysctl -w vm.dirty_expire_centisecs=20000",
        "echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf",
        "echo 'vm.dirty_expire_centisecs=20000' | sudo tee -a /etc/sysctl.conf",
        "sudo ./chef-automate deploy config.toml --product automate --product infra-server --accept-terms-and-mlsa --skip-preflight",
        "bash /tmp/a2_license_apply.sh",
        "sudo rm /tmp/a2_license_apply.sh",
        "sudo rm /tmp/a2_license",
        "export TOK=`sudo chef-automate iam token create admin_token --admin`",
        "sudo chown centos /tmp/automate-credentials.toml",
        "sudo chmod 600 /tmp/automate-credentials.toml",
        "sudo chef-automate iam admin-access restore ${var.a2_admin_password}",
        "bash /tmp/download_compliance_profiles.sh",
        "sudo rm /tmp/download_compliance_profiles.sh",
      ]
    }

    # Create org and user
    provisioner "remote-exec" {
      inline = [
        "echo \"Adding org and user\"",
        "sudo mkdir /opt/chef-keys && sudo chmod 700 /opt/chef-keys/",
        "sudo chef-server-ctl user-create ${var.chef_user["username"]} ${var.chef_user["first_name"]} ${var.chef_user["last_name"]} ${var.chef_user["email"]} ${base64sha256(self.id)} -f /opt/chef-keys/${var.chef_user["username"]}.pem",
        "sudo chmod 600 /opt/chef-keys/${var.chef_user["username"]}.pem",
        "sudo chef-server-ctl org-create ${var.chef_org["short_name"]} '${var.chef_org["long_name"]}' --association_user ${var.chef_user["username"]} --filename /opt/chef-keys/${var.chef_org["short_name"]}-validator.pem",
        "sudo chmod 600 /opt/chef-keys/${var.chef_org["short_name"]}-validator.pem",
        "sudo knife ssl fetch -c /opt/chef-client-config/local_root_client.rb",
      ]
    }
}

#################
# End - A2 Server
#################
