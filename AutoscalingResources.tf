data "aws_ami" "ubuntu" {   
  owners = ["554660509057"]
  filter {                
    name   = "tag:Name"
    values = ["ubuntu"]
  }
  most_recent = true
}
data "aws_security_group" "sg" {
  vpc_id = "vpc-0ce7889ae8fafd3f6"
}
data "template_file" "user_data" {
  template = file("./user_data.tpl")
  vars = {
    name = var.name
    security_group_id = data.aws_security_group.sg.id 
  }
}
resource "aws_launch_template" "httpd" {
  name = var.name
  description = "Sample Template managed by Terraform"
  tags = local.tags
  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "kul"
  vpc_security_group_ids = [ data.aws_security_group.sg.id ]
  tag_specifications {
    resource_type = "instance"
    tags = local.tags
  }
  tag_specifications {
    resource_type = "volume"
    tags = local.tags
  }
  user_data = base64encode(data.template_file.user_data.rendered)
}
resource "aws_lb_target_group" "tg_80" {
  target_type = "instance"
  name = var.name
  protocol = "TCP"
  port = 80
  vpc_id = var.vpc_id
  tags = local.tags
}

resource "aws_autoscaling_group" "asg" {
  name = var.name
  launch_template {
    id = aws_launch_template.httpd.id
    version = "$Default"
  }
  vpc_zone_identifier = module.create_subnet.subnet_ids
  target_group_arns = [ aws_lb_target_group.tg_80.arn ]
  health_check_type = "ELB"
  health_check_grace_period = 180
  desired_capacity = 1
  min_size = 1
  max_size = 3
}
resource "aws_autoscaling_notification" "asg_sns" {
  group_names = [
    aws_autoscaling_group.asg.name
  ]
  topic_arn = "arn:aws:sns:us-east-2:554660509057:kul"
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]
}

resource "aws_autoscaling_policy" "cpuUtilization" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name = "${var.name}-average-cpu-utilization"
  policy_type = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 10
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = var.name
      }
      customized_scaling_metric_specification {
        metric_data_queries {
          id = "scaling"
          metric_stat {
            metric {
              metric_name = "CPUUtilization"
              namespace   = "AWS/EC2"
              dimensions {
                name  = "AutoScalingGroupName"
                value = var.name
              }
            }
            stat = "Average"
          }
        }
      }
    }
  }
}

resource "aws_lb" "httpd" {
  load_balancer_type = "network"
  name = var.name
  internal = false
  subnets = module.create_subnet.subnet_ids
  tags = local.tags
}
resource "aws_lb_listener" "listener_80" {
  load_balancer_arn =  aws_lb.httpd.arn
  protocol = aws_lb_target_group.tg_80.protocol
  port = aws_lb_target_group.tg_80.port
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg_80.arn
  }
  tags = local.tags
}