
#Create firewall container
resource "aws_security_group" "public_web_sg"{
  name = "Public-Web-SG"
  description = "Perimeter Firewall"
  vpc_id = aws_vpc.corporate_core.id

  tags ={
    Name = "Public-Web-SG"
    ManagedBy = "Terraform"
  }
}
#Create firewall rule to allow inbound port 80 traffic
resource "aws_vpc_security_group_ingress_rule" "allow_http"{
  security_group_id = aws_security_group.public_web_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  description = "Allow http traffic inbound"
}
#Create firewall rule to allow inbound port 443 traffic
resource "aws_vpc_security_group_ingress_rule" "allow_https"{
  security_group_id = aws_security_group.public_web_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  description = "Allow https traffic inbound"
}
#Create firewall rule to allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "allow_web_outbound_to_proxy" {
  security_group_id = aws_security_group.public_web_sg.id
  cidr_ipv4 = "${aws_instance.egress_proxy.private_ip}/32"
  ip_protocol = "tcp"
  from_port = 3128
  to_port = 3128
  description = "Outbound streams strictly pinned to squid proxy"
}
#Declaring proxy security group
resource "aws_security_group" "proxy_sg" {
  name        = "proxy-egress-inspection-sg"
  description = "Firewall container for the outbound proxy appliance cluster"
  vpc_id      = aws_vpc.corporate_core.id

  tags = {
    Name        = "Egress-Proxy-Firewall-Container"
    Environment = "Production"
  }
}
#Inbound Shield Rule: Allow internal hosts to reach the Proxy over Squid port 3128
resource "aws_vpc_security_group_ingress_rule" "proxy_allow_internal" {
  security_group_id = aws_security_group.proxy_sg.id
  cidr_ipv4         = "10.0.1.0/24" # Restrict source scope exclusively to our internal network space
  from_port         = 3128
  to_port           = 3128
  ip_protocol       = "tcp"
  description       = "Compliance: Accept local subnet proxy requests over transport layer 4"
}

#Outbound Shield Rule: Allow the Proxy itself to connect out to the internet repo mirrors
#trivy:ignore:AWS-0104 - Sandbox Acceptable: Proxy requires open outbound edge 443 to dynamically track diverse repository mirror pools
resource "aws_vpc_security_group_egress_rule" "proxy_allow_outbound_patching" {
  security_group_id = aws_security_group.proxy_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Proxy egress bound to public TLS sync mirrors"
}