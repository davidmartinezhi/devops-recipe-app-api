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

resource "aws_iam_role" "app_task" { # Assumes same role policy as the task execution role
  name               = "${local.prefix}-app-task"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

resource "aws_iam_policy" "task_ssm_policy" { # Policy to allow System Manager to execute
  name        = "${local.prefix}-task-ssm-role-policy"
  path        = "/"
  description = "Policy to allow System Manager to execute in container"
  policy      = file("./templates/ecs/task-ssm-policy.json")
}

# With S3 we would add a new policy for s3 (task s3 policy) and attach it to the app task role
resource "aws_iam_role_policy_attachment" "task_ssm_policy" { # Attach the policy task ssm policy to the app task role
  role       = aws_iam_role.app_task.name
  policy_arn = aws_iam_policy.task_ssm_policy.arn
}

resource "aws_ecs_cluster" "main" { # ECS cluster configuration
  name = "${local.prefix}-cluster"  # name of the cluster
}
