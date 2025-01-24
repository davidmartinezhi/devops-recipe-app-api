############
# Database #
############

# Create a database subnet group that contains both private subnets (the rds will be available in this subnets)
resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-main"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

# Security group for the database taht will allow access to rds instance
# This will be used for createing to create resources that need to access the db (onnly those resources will be able to access the db)
resource "aws_security_group" "rds" {
  description = "Allow access to the RDS database instance"
  name        = "${local.prefix}-rds-inbound-access"
  vpc_id      = aws_vpc.main.id # We put it in our vpc

  # Allow ingress access to the database from the public subnet
  ingress {
    protocol  = "tcp"
    from_port = 5432 # Port 5432 is the default port for postgress databases
    to_port   = 5432
  }

  tags = {
    Name = "${local.prefix}-db-security-group"
  }
}

# Creating new aws DB resource (RDS)
resource "aws_db_instance" "main" {
  identifier                 = "${local.prefix}-db" # Identifier in AWS
  db_name                    = "recipe"             # Name of the database
  allocated_storage          = 20                   # Storage in GB, this might be increased or decreased based on the usage
  storage_type               = "gp2"                # Type of storage, gp2 is the default, cheapest and general purpose. Depends on read/write operations requirements
  engine                     = "postgres"           # Type of database. We can also create mysql, mariadb, oracle, sqlserver, aurora, etc.
  engine_version             = "15.3"               # Version of postgres we are running
  auto_minor_version_upgrade = true                 # Aws can upgrade minor versions automatically, for security fixes
  instance_class             = "db.t4g.micro"       # Size of the server that will run the db, this impacts the cost (this is the smallest one, it depends on the application)
  username                   = var.db_username      # Credentials to connect to the db inside rds (We'll give this to the app)
  password                   = var.db_password
  skip_final_snapshot        = true                          # Final snapshot is the last backup of the db, we don't need it in this course because we are just testing. In a real life app I would leave it as false
  db_subnet_group_name       = aws_db_subnet_group.main.name # Subnet group that the db will be in, make the db accessible from the private subnets
  multi_az                   = false                         # Multi availability zone, if true it will create a replica in another availability zone. For learning purposes we will leave it as false
  backup_retention_period    = 0                             # Automatic backups retention period in days, 0 means no backups
  vpc_security_group_ids     = [aws_security_group.rds.id]   # Security group that will allow access to the db

  tags = {
    Name = "${local.prefix}-main"
  }
}
