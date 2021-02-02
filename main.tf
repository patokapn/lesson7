provider "aws" {
  region  = "eu-central-1"
}

resource "aws_vpc" "vpc-wordpress" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_security_group" "httpwordpress" {
  name   = "httpwordpress"
  description = "Allow HTTP and SSH traffic"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dbmysql" {
  name   = "dbmysql"
  description = "Allow only db traffic"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "dbwordpress" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "dbwordpress"
  username             = "admin"
  password             = "q1w2e3r4"
  skip_final_snapshot  = true
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.dbmysql.id]
}

resource "aws_s3_bucket" "s3wordpress-http-mysql" {
  bucket = "s3wordpress-http-mysql"
  acl = "public-read"
}

resource "aws_instance" "httpwordpress" {
  ami                    = "ami-0502e817a62226e03" # Ubuntu Server 20.04 LTS
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.httpwordpress.id]
  user_data = "${file("init-script.sh")}"
  depends_on = [aws_db_instance.dbwordpress]
}