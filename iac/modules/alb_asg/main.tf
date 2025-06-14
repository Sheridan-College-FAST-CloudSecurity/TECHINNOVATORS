#resource "aws_launch_template" "web_lt" {
#  name_prefix   = "techinnovators-lt-"
#  image_id      = "ami-0c02fb55956c7d316"
#  instance_type = "t2.micro"

#  user_data = base64encode(<<EOF
#!/bin/bash
#yum install -y nginx
#systemctl enable nginx
#systemctl start nginx
#EOF
#  )

#  tag_specifications {
#    resource_type = "instance"
#    tags = {
#      Name = "techinnovators-instance"
#    }
#  }
#}
