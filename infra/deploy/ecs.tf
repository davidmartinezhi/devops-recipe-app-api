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

# Create the log group for the ECS task, logs outputs from dokcer containers and stores them in cloudwatch
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-api"
}

resource "aws_ecs_cluster" "main" { # ECS cluster configuration
  name = "${local.prefix}-cluster"  # name of the cluster
}

# Defines the task that will run in ECS
# We define resources, type, capabilities and other configurations
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.prefix}-api"                # name of the task
  requires_compatibilities = ["FARGATE"]                          # Fargate compatibility, type of task that is serverless 
  network_mode             = "awsvpc"                             # Type of network, which is our vpc
  cpu                      = 256                                  # CPU for the task, this is important value. This determines how much we are gonna be charged
  memory                   = 512                                  # Memory for the task, this is important value. This determines how much we are gonna be charged
  execution_role_arn       = aws_iam_role.task_execution_role.arn # Link to role created above that contains execution role
  task_role_arn            = aws_iam_role.app_task.arn            # Role assigned to running task once it has already started

  container_definitions = jsonencode([]) # Container definitions, we will add this later

  # Volume is the location on the running server that has files
  # It allows to share data between running containers. (app and proxy in our case) 
  volume {
    name = "static" # Volume name
  }

  # Defines the type of server that are containers are going to run on
  runtime_platform {
    operating_system_family = "LINUX"  # Operating system family
    cpu_architecture        = "X86_64" # CPU architecture
  }
}
