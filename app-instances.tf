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
    user = "ubuntu"
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
    source      = "daemon.json"
    destination = "/etc/docker/daemon.json"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart docker",
      "sudo docker swarm init"
    ]
  }
  tags {
    Name = "Anton/Sharpaev"
  }
}

