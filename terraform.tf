  
provider "aws" {
  region = "ap-south-1"
  //profile = "deepanshu2"
}




//creating private key
resource "tls_private_key" "mykey" {
  algorithm = "RSA"
}
resource "aws_key_pair" "generated_key" {
  key_name = "my_key"
  public_key = tls_private_key.mykey.public_key_openssh

depends_on = [
   tls_private_key.mykey
        ]
}

resource "local_file" "keyfile" {
  content = tls_private_key.mykey.private_key_pem

 filename = "mykey.pem"
depends_on=[aws_key_pair.generated_key]

         }
//launching security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "SSH"
    from_port   =22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls1"
  }
}

//creating instance
resource "aws_instance" "first_instance" {
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  security_groups = [ "allow_tls" ]
  key_name = aws_key_pair.generated_key.key_name

  tags = {
    Name = "myfirstos"
  }

  
}

// creating ebs volume
resource "aws_ebs_volume" "ebs_volume" {
depends_on = [
    aws_instance.first_instance,
  ]
  availability_zone = aws_instance.first_instance.availability_zone
  size              = 1

  tags = {
    Name = "ebs1"
  }
}
//attaching ebs volume to instance
resource "aws_volume_attachment" "ebs_att" {
depends_on = [
    aws_ebs_volume.ebs_volume
   ]
  device_name = "/dev/xvdh"
  force_detach = true
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.first_instance.id
}



