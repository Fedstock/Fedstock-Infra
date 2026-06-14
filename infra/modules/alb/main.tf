resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow public HTTP traffic to the ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.allowed_ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = var.certificate_arn == null ? [] : toset(var.allowed_ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.name_prefix}-backend-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-tg"
  })
}

resource "aws_lb_target_group" "ai_backend" {
  count = var.enable_ai_backend ? 1 : 0

  name        = "${var.name_prefix}-ai-backend-tg"
  port        = var.ai_backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/ai/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ai-backend-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [1] : []

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.backend.arn
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn == null ? [] : [1]

    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_lb_listener_rule" "ai_health" {
  count = var.enable_ai_backend ? 1 : 0

  listener_arn = var.certificate_arn == null ? aws_lb_listener.http.arn : aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_backend[0].arn
  }

  condition {
    path_pattern {
      values = ["/ai/health"]
    }
  }
}

resource "aws_lb_listener_rule" "ai_health_http" {
  count = var.enable_ai_backend && var.certificate_arn != null ? 1 : 0

  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_backend[0].arn
  }

  condition {
    path_pattern {
      values = ["/ai/health"]
    }
  }
}

resource "aws_lb_listener_rule" "ai" {
  count = var.enable_ai_backend ? 1 : 0

  listener_arn = var.certificate_arn == null ? aws_lb_listener.http.arn : aws_lb_listener.https[0].arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_backend[0].arn
  }

  condition {
    path_pattern {
      values = ["/ai/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ai_http" {
  count = var.enable_ai_backend && var.certificate_arn != null ? 1 : 0

  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_backend[0].arn
  }

  condition {
    path_pattern {
      values = ["/ai/*"]
    }
  }
}

resource "aws_lb_listener_rule" "backend_health" {
  listener_arn = var.certificate_arn == null ? aws_lb_listener.http.arn : aws_lb_listener.https[0].arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = var.certificate_arn == null ? aws_lb_listener.http.arn : aws_lb_listener.https[0].arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
