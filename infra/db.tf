resource "aws_security_group" "db-sg" {
  vpc_id = aws_vpc.main.id
  name   = "db-sg"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

resource "aws_db_subnet_group" "db-tier-subnet-group" {
  name        = "db-tier-subnet-group"
  description = "subnet-group in db tier"
  subnet_ids  = values(aws_subnet.db-tier)[*].id
}

resource "aws_db_instance" "main-freetier-db" {
  allocated_storage                   = 20
  engine                              = "mysql"
  engine_version                      = "8.0.33"
  instance_class                      = "db.t3.micro"
  username                            = "root"
  parameter_group_name                = "default.mysql8.0"
  skip_final_snapshot                 = true
  copy_tags_to_snapshot               = true
  storage_type                        = "gp2"
  backup_target                       = "region"
  backup_retention_period             = 1
  customer_owned_ip_enabled           = false
  deletion_protection                 = false
  max_allocated_storage               = 1000
  enabled_cloudwatch_logs_exports     = []
  iam_database_authentication_enabled = false
  storage_encrypted                   = true
  backup_window                       = "16:02-16:32"
  vpc_security_group_ids              = [aws_security_group.db-sg.id]
  password                            = "12341234"
  db_subnet_group_name                = aws_db_subnet_group.db-tier-subnet-group.name

  lifecycle {
    ignore_changes = ["password"]
  }
}
