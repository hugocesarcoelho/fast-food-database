terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "hugo-organization"

    workspaces {
      name = "learn-terraform-github-actions"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "sg" {}

# Generate a random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Store the password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name = "mysql-rds-password"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.db_password.result
}

# Security Group for RDS
resource "aws_security_group" "rds-sg" {
  name = "${random_pet.sg.id}-rds-sg"

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

# Create an RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier             = "fiap-mysql-db-2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = "admin"
  password               = random_password.db_password.result
  db_name                = "fiapdb"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]

  tags = {
    Name = "fiap-mysql-db"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

# # Security Group for Redis
# resource "aws_security_group" "redis-sg" {
#   name = "${random_pet.sg.id}-redis-sg"

#   ingress {
#     from_port   = 6379
#     to_port     = 6379
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # Subnet Group for Redis
# resource "aws_elasticache_subnet_group" "redis" {
#   name       = "redis-subnet-group"
#   subnet_ids = ["subnet-0e6be6f8c1d2d0232", "subnet-051df09ed3adb7510", "subnet-002e1c254379eae5b", "subnet-0a40b6e40973981bf", "subnet-007d0f8c197010954", "subnet-0194eafe9eca9838b"] # Replace with actual subnet IDs
# }

# # Redis Cluster
# resource "aws_elasticache_cluster" "redis" {
#   cluster_id           = "fiap-redis-cluster"
#   engine               = "redis"
#   node_type            = "cache.t3.micro"
#   num_cache_nodes      = 1
#   parameter_group_name = "default.redis7"
#   port                 = 6379
#   security_group_ids   = [aws_security_group.redis-sg.id]
#   subnet_group_name    = aws_elasticache_subnet_group.redis.name

#   tags = {
#     Name = "fiap-redis"
#   }
# }

# output "redis_endpoint" {
#   value = aws_elasticache_cluster.redis.cache_nodes[0].address
# }
