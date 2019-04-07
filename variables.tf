
variable "NameTag" {
    type = "string"
    default = "tutorial"
}
variable "private_subnet_cidr" {
    description = "CIDR for the private subnet"
    default = "192.168.1.0/24"
}

variable "public_subnet_cidr" {
    description = "CIDR for the public subnet"
    default = "192.168.2.0/24"
}

variable "INSTANCE_TYPE" {
    default = "t2.micro"
}
variable "INSTANCE_USERNAME" {
    default = "root"
}
variable "INSTANCE_PASSWORD" {
    default = ""
}