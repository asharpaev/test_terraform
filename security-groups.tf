resource "aws_security_group" "swarm" {
  name = "ASharpaev_group"

  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMPv4"
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["CHANGEME"]
    description = "SSH"
  }

  ingress {
    from_port = 2376
    to_port   = 2376
    protocol  = "tcp"
    cidr_blocks = ["CHANGEME"]
    description = "Docker API"
  }

  ingress {
    from_port = 2377
    to_port   = 2377
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Docker Swarm traffic"
  }


  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins"
  }

  ingress {
    from_port = 9000
    to_port   = 9000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Docker logs web app"
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound policy ACCEPT"
  }

  tags {
    Name = "Anton/Sharpaev"
  }
}