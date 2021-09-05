# Provider que o Terraform irá utilizar
provider "aws" {
  region = var.region
}

# VPC padrão da região
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

################################ Inicio da Criação de Grupos de Segurança #################################### 

# Security Group para o ALB
resource "aws_security_group" "sg-alb-http" {
  name = "SecurityGroupHTTPForALB"

  # Liberar a porta 80 para acesso livre via Internet
  ingress = [
    {
      description      = "HTTP access ingress rule"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  egress = [
    {
      description      = "All access egress rule"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  tags = {
    Name = "SecurityGroupHTTPForALB"
  }
}

# Security Group para as instâncias do Tomcat
resource "aws_security_group" "sg-tomcat-http" {
  name = "SecurityGroupHTTPForTomcat"

  # Liberar a porta 80 para acesso livre via Internet
  ingress = [
    {
      description      = "HTTP access ingress rule"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

    egress = [
    {
      description      = "All access egress rule"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  tags = {
    Name = "SecurityGroupHTTPForTomcat"
  }
}

# Security Group para a instância do Jenkins
resource "aws_security_group" "sg-jenkins-default" {
  name = "SecurityGroupForJenkins"

  # Liberar a porta 8080 para acesso livre via Internet
  ingress = [
    {
      description      = "HTTP access ingress rule"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

    egress = [
    {
      description      = "All access egress rule"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  tags = {
    Name = "SecurityGroupForJenkins"
  }
}

# Security Group para conexão SSH nas instâncias
resource "aws_security_group" "sg-ec2-ssh" {
  name = "SecurityGroupSSHForEC2"

  # Libera a porta 22 para acesso 
  ingress = [
    {
      description      = "SSH access ingress rule"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  tags = {
    Name = "SecurityGroupSSHForEC2"
  }
}

# Security Group para o RDS MySQL
resource "aws_security_group" "sg-rds-mysql" {
  name = "SecurityGroupForMySQL"

  ingress = [
    {
      description      = "MySQL default port ingress rule"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null
      security_groups = null
      self = null
    }
  ]

  tags = {
    Name = "SecurityGroupForMySQL"
  }

}

################################ Fim da criação de Grupos de Segurança #################################### 


################################ Inicio da Criação de Instancias EC2 #########################################

## EC2 Instances Apache Tomcat
resource "aws_instance" "apache-tomcat" {

  count = 2

  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_name
  user_data       = file("scripts/install_apache_tomcat.sh")
  security_groups = ["${aws_security_group.sg-tomcat-http.name}", "${aws_security_group.sg-ec2-ssh.name}"]

  tags = {
    Name = "apache-tomcat-n${count.index}"
  }

}

## EC2 Instance Jenkins
resource "aws_instance" "jenkins" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = ["${aws_security_group.sg-jenkins-default.name}", "${aws_security_group.sg-ec2-ssh.name}"]
  user_data       = file("scripts/install_jenkins.sh")

  tags = {
    Name = "jenkins-n1"
  }
}

################################ Fim da Criação de Instancias EC2 ##############################################

################################ Ininio da Criação do Banco de Dados MySQL #####################################

# DB Intance MySql
resource "aws_db_instance" "rds-mysql" {

  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = var.username
  password             = var.password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = true

  vpc_security_group_ids = [aws_security_group.sg-rds-mysql.id]

  tags = {
    Name = "mysql"
  }
}

################################ Fim da Criação do Banco de Dados MySQL #####################################

################################ Inicio da Configuração do Load Balance ####################################

## Configuração do Application Load Balance
resource "aws_alb" "ec2-alb" {
  name               = "ec2-alb"
  security_groups    = [aws_security_group.sg-alb-http.id]
  subnets            = ["subnet-a58a19c3", "subnet-ffbf2eb6"]

  tags = {
    Name = "ec2-alb"
  }
}

# Configuração do target group para o Application Load Balance
resource "aws_alb_target_group" "ec2-alb-target-group" {
  name     = "ec2-alb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id = aws_default_vpc.default.id

  health_check {
    path = "/"
    port = 8080
  }
}

# Associando as instâncias do Apache ao Target Group
resource "aws_alb_target_group_attachment" "ec2-alb-target-group-attachment" {

  count = 2

  target_group_arn = aws_alb_target_group.ec2-alb-target-group.arn
  target_id        = aws_instance.apache-tomcat[count.index].id
  port             = 8080
}

# Criando um Listener para a porta 80
resource "aws_lb_listener" "ec2-alb-listener-http" {
  load_balancer_arn = aws_alb.ec2-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ec2-alb-target-group.arn
  }
}

################################ Fim da Configuração do Load Balance ####################################