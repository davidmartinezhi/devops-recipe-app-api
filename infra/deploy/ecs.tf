##########################################
# ECS Cluster for tunning app on Fargate #
##########################################


resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster" # name of the cluster
}
