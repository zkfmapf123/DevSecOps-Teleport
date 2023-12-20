variable "az" {
  type    = string
  default = "ap-northeast-2"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "webserver_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "was_cidr" {
  type    = list(string)
  default = ["10.0.100.0/24", "10.0.101.0/24"]
}

variable "db_cidr" {
  type    = list(string)
  default = ["10.0.200.0/24", "10.0.201.0/24"]
}

locals {
  az = "ap-northeast-2"

  webserver_cidr = var.webserver_cidr
  was_cidr       = var.was_cidr
  db_cidr        = var.db_cidr

  azs = [
    for _, v in ["a", "b"] : "${local.az}${v}"
  ]

  webserver_tier = {
    for i, v in local.azs :
    v => local.webserver_cidr[i]
  }

  was_tier = {
    for i, v in local.azs :
    v => local.was_cidr[i]
  }

  db_tier = {
    for i, v in local.azs :
    v => local.db_cidr[i]
  }
}

###################################### AWS VPC ######################################
resource "aws_vpc" "main" {
  cidr_block = var.cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name     = "main-vpc"
    Resource = "vpc"
  }
}

###################################### Internet-gateway ######################################
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name     = "main-igw"
    Resource = "igw"
  }
}

###################################### 1 tier subnet ######################################
resource "aws_subnet" "webserver-tier" {
  for_each = local.webserver_tier

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name     = "webserver-${each.key}"
    Resource = "subnet"
  }
}

###################################### 2 tier subnet ######################################
resource "aws_subnet" "was-tier" {
  for_each = local.was_tier

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name     = "private-was-${each.key}"
    Resource = "subnet"
  }
}

###################################### 3 tier subnet ######################################
resource "aws_subnet" "db-tier" {
  for_each = local.db_tier

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name     = "private-db-${each.key}"
    Resource = "subnet"
  }
}

###################################### 1 tier route-table + nat-gateway ######################################
resource "aws_route_table" "webserver-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
}

resource "aws_route_table_association" "webserver-rt-mapping" {
  for_each = aws_subnet.webserver-tier

  subnet_id      = each.value.id
  route_table_id = aws_route_table.webserver-rt.id
}

resource "aws_eip" "nat-eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = lookup(aws_subnet.webserver-tier, "ap-northeast-2a").id

  tags = {
    Name = "nat"
  }
}

###################################### 2 tier route-table ######################################
resource "aws_route_table" "was-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "was-rt-mapping" {
  for_each = aws_subnet.was-tier

  subnet_id      = each.value.id
  route_table_id = aws_route_table.was-rt.id
}

###################################### 3 tier route-table ######################################
# resource "aws_route_table" "db-rt" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat.id
#   }
# }

# resource "aws_route_table_association" "db-rt-mapping" {
#   for_each = aws_subnet.db-tier

#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.db-rt.id
# }

output "vpc" {
  value = {
    vpc_id = aws_vpc.main.id
    az     = local.az
    webservers = {
      for _, v in aws_subnet.webserver-tier :
      v.availability_zone => v.id
    }

    was = {
      for _, v in aws_subnet.was-tier :
      v.availability_zone => v.id
    }

    db = {
      for _, v in aws_subnet.db-tier :
      v.availability_zone => v.id
    }
  }
}
