output "public-dns-jenkins" {
  value = aws_instance.jenkins.public_dns
}

output "public-dns-apache-tomcat-n1" {
  value = aws_instance.apache-tomcat[0].public_ip
}

output "public-dns-apache-tomcat-n2" {
  value = aws_instance.apache-tomcat[1].public_ip
}

output "alb-public-dns" {
  value = aws_alb.ec2-alb.dns_name
}

output "address-rds-mysql" {
  value = aws_db_instance.rds-mysql.address
}