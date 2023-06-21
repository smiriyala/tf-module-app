resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"

  /* iam_instance_profile {
    name = "test"
  } */

  image_id = data.aws_ami.ami.image_id


  instance_market_options {
    market_type = "spot"
  }

  instance_type = var.instance_type


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