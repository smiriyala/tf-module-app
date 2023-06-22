resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"

  #this intance profile created in iam.tf and referring here.
  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  image_id = data.aws_ami.ami.image_id


  instance_market_options {
    market_type = "spot"
  }

  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]


  tag_specifications {
    resource_type = "instance"

    tags = merge(
        var.tags,
        { Name = "${var.component}-${var.env}" }
    )
  }

  ## OPTION-A : in this step, userdata.sh file being called to execute in part of launching instance using template
  # component and env variables values passed using data.tf file.

  /* user_data = filebase64("${path.module}/userdata.sh") */

  # OPITON - B other approch is
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    component = var.component
    env = var.env
  } ))

}

resource "aws_autoscaling_group" "main" {
  /* availability_zones = ["us-east-1a"] */
  name = "${var.component}-${var.env}"
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnets

  #Session-46 - LoadBalancer
  #step-4 - Attach Target Group to ALB  - DONE
  target_group_arns = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key = "Name"
    propagate_at_launch = false
    value = "${var.component}-${var.env}"
  }
}


##lets create security group as none of the machines are connectable. 
resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}"
  description = "${var.component}-${var.env}"
  vpc_id      = var.vpc_id

  # this port help to connect from bastion/workstation machine.
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr
  }

  #this port opening helps to connect with in APP Servers
  ingress {
    description      = "APP"
    from_port        = var.port
    to_port          = var.port
    protocol         = "tcp"
    cidr_blocks      = var.allow_app_to
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    { Name = "${var.component}-${var.env}" }
  )
}

#Session-46 - LoadBalancer
#STEP 3 - Crate Target Group
# This target group need to attached to AUTOSCALING_GROUP
resource "aws_lb_target_group" "main" {
  name     = "${var.component}-${var.env}-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 5
    interval = 4
    timeout = 4
  }
  tags = merge(
    var.tags,
    { Name = "${var.component}-${var.env}" }
  )
}

#Session-46 - LoadBalancer
#STEP 5- Crate CNAME record - DONE
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = local.dns_name
  type    = "CNAME"
  ttl     = "30"

  #This record is comming from ALB
  records = [var.alb_dns_name]
}

#Session-46 - LoadBalancer
#STEP 6- Add rule in listener
resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = var.listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = [local.dns_name]
    }
  }
}