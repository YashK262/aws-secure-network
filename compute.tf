#Launch ec2 instance
resource "aws_instance" "web_server"{
  ami = "ami-0d351f1b760a30161"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_tier_1a.id
  vpc_security_group_ids = [aws_security_group.public_web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Success:Infrastructure via Terraform</h1>" > /var/www/html/index.html
              EOF
  #AWS-0131, encrypting root drive
  root_block_device {
    encrypted = "true"
    volume_type = "gp3"
  }
  #To enforce IMDSV2 session handshaked, IMDSV1 is vulnerable AWS-0028
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
  }
  tags = {
    Name = "Public-Web-Server"
    Environment = "Production"
    ManagedBy = "Terraform"
  }
}
output "server_public_ip"{
  description = "Public ip of the ec2 instance"
  value = aws_instance.web_server.public_ip
}
#Creating fowrarding proxy
resource "aws_instance" "egress_proxy" {
  ami = "ami-0d351f1b760a30161"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_tier_1a.id
  vpc_security_group_ids = [ aws_security_group.proxy_sg.id ]

  user_data = <<-EOF
              #!bin/bash
              sudo yum update -y
              sudo yum install squid -y
              sudo systemctl start squid
              sudo systemctl enable squid
              EOF
  #AWS-0131, encrypting root drive
  root_block_device {
    encrypted = "true"
    volume_type = "gp3"
  }
  #To enforce IMDSV2 session handshaked, IMDSV1 is vulnerable AWS-0028
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
  }
  tags = {
    Name = "Secure-Egress-Proxy-SWG"
    Environment = "Production"
  }
}
# The Private IP anchor for the Proxy instance to allow tight firewall rules
resource "aws_network_interface" "proxy_nic" {
  subnet_id = aws_subnet.public_tier_1a.id
}