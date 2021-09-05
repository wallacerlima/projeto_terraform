# Default Region
variable "region" {
  description = "AWS Region"
  default     = "sa-east-1"
}

# Tipo da AMI que será utilizada para as EC2
variable "ami" {
  description = "AMI"
  default     = "ami-054a31f1b3bf90920" //server para a região sa-east-1
}

# Classe da instância que será utilizada
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

#Chave de acesso
variable "key_name" {
  description = "Key SSH"
  default     = "terraform-multi"
}

#Usuário de acesso ao MySQL
variable "username" {
  description = "User Mysql"
  default     = "admin"
}

#Senha de acesso ao Mysql
variable "password" {
  description = "Password Mysql"
  default     = "QwErTy123"
}

#Zonas de disponibilidade
variable "availability_zones" {
  description = "Zones"
  default     = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  type        = list(string)
}