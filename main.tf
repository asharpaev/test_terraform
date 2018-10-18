provider "aws" {
    access_key  = "${var.access_key}"
    secret_key  = "${var.secret_key}"
    region      = "${var.region}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "master" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  connection {
    user = "${var.user}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install apt-transport-https ca-certificates curl",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get -y install docker-ce",
      "sudo sed -i 's/ExecStart.*/ExecStart=\\/usr\\/bin\\/dockerd/g' /lib/systemd/system/docker.service",
      "sudo systemctl daemon-reload",
      "sudo chmod 777 /etc/docker"
    ]
  }
  provisioner "file" {
    source      = "conf/daemon.json"
    destination = "/etc/docker/daemon.json"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart docker",
      "sudo docker swarm init"
    ]
  }
  tags {
    Name = "Anton/Sharpaev master"
  }

}

data "external" "swarm_tokens" {
  program = ["bash", "${path.module}/scripts/get_swarm_tokens.sh"]

  query = {
    host = "${aws_instance.master.public_ip}"
    user = "${var.user}"
  }

  depends_on = ["aws_instance.master"]
}


resource "aws_instance" "worker" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.swarm.name}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  connection {
    user = "${var.user}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install apt-transport-https ca-certificates curl",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get -y install docker-ce",
      "sudo sed -i 's/ExecStart.*/ExecStart=\\/usr\\/bin\\/dockerd/g' /lib/systemd/system/docker.service",
      "sudo systemctl daemon-reload",
      "sudo chmod 777 /etc/docker"
    ]
  }
  provisioner "file" {
    source      = "conf/daemon.json"
    destination = "/etc/docker/daemon.json"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart docker",
      "sudo docker swarm join --token ${data.external.swarm_tokens.result["worker"]} ${aws_instance.master.private_ip}:2377"
    ]
  }
  tags {
    Name = "Anton/Sharpaev worker"
  }

}


resource "aws_security_group_rule" "allow_swarm_node_communication_tcp" {
  type            = "ingress"
  from_port       = 7946
  to_port         = 7946
  protocol        = "tcp"
  cidr_blocks     = [
                        "${aws_instance.master.private_ip}/32",
                        "${aws_instance.worker.private_ip}/32"
                    ]
  description      = "Swarm nodes traffic tcp"
  security_group_id = "${aws_security_group.swarm.id}"
}

resource "aws_security_group_rule" "allow_swarm_node_communication_udp" {
  type            = "ingress"
  from_port       = 7946
  to_port         = 7946
  protocol        = "udp"
  cidr_blocks     = [
                        "${aws_instance.master.private_ip}/32",
                        "${aws_instance.worker.private_ip}/32"
                    ]
  description      = "Swarm nodes traffic udp"
  security_group_id = "${aws_security_group.swarm.id}"
}

resource "aws_security_group_rule" "allow_swarm_overlay_network_traffic" {
  type            = "ingress"
  from_port       = 4789
  to_port         = 4789
  protocol        = "udp"
  cidr_blocks     = [
                        "${aws_instance.master.private_ip}/32",
                        "${aws_instance.worker.private_ip}/32"
                    ]
  description      = "Swarm overlay network traffic"
  security_group_id = "${aws_security_group.swarm.id}"
}