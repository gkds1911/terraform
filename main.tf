# refaire les security groups
#1 pour l'elb web
#1 pour l'elb app
#1 pour les instance web
#1 pour les instance app
data "aws_availability_zones" "available" {}
data "aws_ami" "latestwindows2019" {
    most_recent      = true
    owners           = ["amazon"]

    filter {
        name = "name"
        values = ["Windows_Server-2019-English-Full-Base-*"]
    }

    filter {
        name = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
resource "aws_vpc" "phvpc" {
    cidr_block       = "192.168.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_internet_gateway" "phgw" {
    vpc_id = "${aws_vpc.phvpc.id}"

    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_route_table" "phrtb" {
    vpc_id  = "${aws_vpc.phvpc.id}"
    tags = {
        Name = "${var.NameTag}"
    }
    route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.phgw.id}"
    }    
}
resource "aws_route_table_association" "phrtbassoc" {
    subnet_id   = "${aws_subnet.websubnet.id}"    
    route_table_id = "${aws_route_table.phrtb.id}"
}
resource "aws_elb" "webelb" {
    #availability_zones = ["${data.aws_availability_zones.available.names}"]
    tags = {
        Name = "${var.NameTag}"
    }    
    instances   = ["${aws_instance.webvm.*.id}"]
    listener = {
        instance_port = "80"
        instance_protocol = "TCP"
        lb_port = "80"
        lb_protocol = "TCP"
    }
    security_groups = ["${aws_security_group.webelbsg.id}"]    
    subnets         = ["${aws_subnet.websubnet.id}"]
}
resource "aws_elb" "appelb" {
    #availability_zones = ["${data.aws_availability_zones.available.names}"]
    tags = {
        Name = "${var.NameTag}"
    }
    instances   = ["${aws_instance.appvm.*.id}"]
    listener = {
        instance_port = "8080"
        instance_protocol = "TCP"
        lb_port = "8080"
        lb_protocol = "TCP"
    }
    security_groups = ["${aws_security_group.appelbsg.id}"]
    subnets         = ["${aws_subnet.appsubnet.id}"]
}
resource "aws_security_group" "webelbsg" {
    description     = "WebELBSG - Tutorial"    
    vpc_id          = "${aws_vpc.phvpc.id}"
    
    ingress = {
        description = "80 from outside"
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 80
        to_port     = 80
        protocol    = "TCP"
    }
    egress = {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
    }   
    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_security_group" "appelbsg" {
    description     = "AppELBSG - Tutorial"    
    vpc_id          = "${aws_vpc.phvpc.id}"
    ingress = {
        description = "8080 from webvms"
        #security_groups = ["${aws_security_group.websg.id}"]
        cidr_blocks = ["${aws_subnet.websubnet.cidr_block}"]
        from_port   = 8080
        to_port     = 8080
        protocol    = "TCP"
    }  
    egress = {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
    }   
    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_security_group" "websg" {
    description     = "WebSG - Tutorial"    
    vpc_id          = "${aws_vpc.phvpc.id}"
    ingress = {
        description = "RDP"
        cidr_blocks = ["91.166.217.76/32"]
        from_port   = 3389
        to_port     = 3389
        protocol    = "TCP"
    }
    ingress = {
        description = "In from WEBELB"
        security_groups = ["${aws_security_group.webelbsg.id}"]
        from_port   = 80
        to_port     = 80
        protocol    = "TCP"        
    }    
    egress = {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
    }   
    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_security_group" "appsg" {
    description     = "AppSG - Tutorial"    
    vpc_id          = "${aws_vpc.phvpc.id}"
    ingress = {
        description = "In from APPELB"
        security_groups = ["${aws_security_group.appelbsg.id}"]
        from_port   = 8080
        to_port     = 8080
        protocol    = "TCP"        
    }   
    egress = {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
    }   
    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_subnet" "websubnet" {
    vpc_id          = "${aws_vpc.phvpc.id}" 
    cidr_block      = "${var.public_subnet_cidr}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"

    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_subnet" "appsubnet" {
    vpc_id          = "${aws_vpc.phvpc.id}" 
    cidr_block      = "${var.private_subnet_cidr}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"

    tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_instance" "webvm" {
    ami             = "${data.aws_ami.latestwindows2019.id}"
    instance_type   = "${var.INSTANCE_TYPE}"
    key_name        = "Terraform"
    subnet_id       = "${aws_subnet.websubnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.websg.id}"]
    associate_public_ip_address = "true"
    count           = 2
    get_password_data = true    
    user_data = "${template_file.iis.rendered}"
    tags = {
        Name = "Web-${count.index}"
    }
    volume_tags = {
        Name = "${var.NameTag}"
    }
}
resource "aws_instance" "appvm" {
    ami             = "${data.aws_ami.latestwindows2019.id}"
    instance_type   = "${var.INSTANCE_TYPE}"
    associate_public_ip_address = "false"    
    key_name        = "Terraform"
    subnet_id       = "${aws_subnet.appsubnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.appsg.id}"]
    associate_public_ip_address = "true"
    count           = 2
    get_password_data = true    
    user_data = "${template_file.password.rendered}"
    tags = {
        Name = "App-${count.index}"
    }
    volume_tags = {
        Name = "${var.NameTag}"
    }
}

resource "template_file" "password" {
    
    template = "${file("./setpassword.ps1")}"
   
    vars {
      admin_password="${var.INSTANCE_PASSWORD}"
    }
}
resource "template_file" "iis" {
    
    template = "${file("./installrole.ps1")}"
   
    vars {
      admin_password="${var.INSTANCE_PASSWORD}"
    }
}


