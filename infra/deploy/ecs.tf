##########################################
# ECS Cluster for tunning app on Fargate #
##########################################

resource "aws_iam_policy" "task_execution_role_policy" { # Create the policy for the task execution
  name        = "${local.prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow ECS to retrieve images and add to logs."
  policy      = file("./templates/ecs/task-execution-role-policy.json") # policy file
}

resource "aws_iam_role" "task_execution_role" { # Create the role for the task execution
  name               = "${local.prefix}-task-execution-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json") # policy file
}

resource "aws_iam_role_policy_attachment" "task_execution_role" { # attach the policy to the role
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

resource "aws_ecs_cluster" "main" { # ECS cluster configuration
  name = "${local.prefix}-cluster"  # name of the cluster
}
