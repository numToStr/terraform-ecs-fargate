locals {
  service_name = "backend"
}

########### ECS CLUSTER ###########

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

########### TASK DEFINITION ###########

resource "aws_ecs_task_definition" "backend" {
  family             = "${var.cluster_name}-backend"
  execution_role_arn = aws_iam_role.task_execution_role.arn

  container_definitions = file("${path.module}/task-definitions/backend.json")

  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]

  network_mode = "awsvpc"
}

########### ECS SERVICE ###########

resource "aws_security_group" "backend_service" {
  name   = "${var.cluster_name}-${local.service_name}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    security_groups = [var.alb_security_group]
  }
}

resource "aws_ecs_service" "this" {
  name            = local.service_name
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false

    security_groups = [aws_security_group.backend_service.id]

    subnets = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = local.service_name
    container_port   = 80
  }
}
