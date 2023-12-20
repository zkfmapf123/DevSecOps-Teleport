########################################### Webserver ###########################################
resource "aws_security_group" "webserver-sg" {
  vpc_id = aws_vpc.main.id
  name   = "webserver-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver-ins-sg"
  }
}

module "default-webserver-ins" {
  source = "zkfmapf123/simpleEC2/lee"

  instance_name      = "teleport-ins"
  instance_region    = "${local.az}a"
  instance_subnet_id = lookup(aws_subnet.webserver-tier, "${local.az}a").id
  instance_sg_ids    = [aws_security_group.webserver-sg.id]

  instance_ip_attr = {
    is_public_ip  = true
    is_eip        = true
    is_private_ip = false
    private_ip    = ""
  }

  instance_key_attr = {
    is_alloc_key_pair = false
    is_use_key_path   = true
    key_name          = ""
    key_path          = "~/.ssh/id_rsa.pub"
  }

  instance_tags = {
    "Monitoring" : true,
    "MadeBy" : "terraform"
  }
}

########################################### WAS ###########################################
resource "aws_security_group" "was-sg" {
  vpc_id = aws_vpc.main.id
  name   = "was-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "was-ins-sg"
  }
}
module "default-was-ins" {
  source = "zkfmapf123/simpleEC2/lee"

  instance_name      = "was-ins"
  instance_region    = "${local.az}a"
  instance_subnet_id = lookup(aws_subnet.was-tier, "${local.az}a").id
  instance_sg_ids    = [aws_security_group.was-sg.id]

  instance_ip_attr = {
    is_public_ip  = false
    is_eip        = false
    is_private_ip = true
    private_ip    = cidrhost(var.was_cidr[0], 10)
  }

  instance_key_attr = {
    is_alloc_key_pair = false
    is_use_key_path   = true
    key_name          = ""
    key_path          = "~/.ssh/id_rsa.pub"
  }

  instance_tags = {
    "Monitoring" : true,
    "MadeBy" : "terraform"
  }
}
