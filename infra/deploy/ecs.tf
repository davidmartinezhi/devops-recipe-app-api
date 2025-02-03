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

  container_definitions = jsonencode(
    [ # Container definition for our app and proxy
      {
        name              = "api"             # Name of the container
        image             = var.ecr_app_image # Image of the container in ecr. Location of the image
        essential         = true              # Essential means that if the container fails, the task will fail
        memoryReservation = 256               # Memory reservation for the container. Must not exceed the amount of memory allocated to the whole task
        user              = "django-user"     # User that is going to run the container.
        environment = [                       # Environment variables set for our running container
          {
            name  = "DJANGO_SECRET_KEY"
            value = var.django_secret_key
          },
          {
            name  = "DB_HOST"
            value = aws_db_instance.main.address # Address of the database (hostname)
          },
          {
            name  = "DB_NAME"
            value = aws_db_instance.main.db_name # Name of the database inside postgres
          },
          {
            name  = "DB_USER"
            value = aws_db_instance.main.username # Username for the database
          },
          {
            name  = "DB_PASS"
            value = aws_db_instance.main.password # Password for the database
          },
          {
            name  = "ALLOWED_HOSTS"
            value = "*" # Allowed hosts for the app
          }
        ]
        mountPoints = [
          {
            readOnly      = false
            containerPath = "/vol/web/static"
            sourceVolume  = "static"
          }
        ],
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = "api"
          }
        }
      },

      # Container definition for the proxy. 
      # Proxy receives request by hhtp, server=s statis files and passes requests to django app
      {
        name              = "proxy"             # Name of the container
        image             = var.ecr_proxy_image # Image of the container in ecr. Location of the image
        essential         = true                # Essential means that if the container fails, the task will fail
        memoryReservation = 256                 # Memory reservation for the container. Must not exceed the amount of memory allocated to the whole task
        user              = "nginx"             # User that is going to run the container. 
        portMappings = [                        # Port mapping for the container
          {
            containerPort = 8000
            hostPort      = 8000
          }
        ]
        environment = [ # Environment variables set for our running container
          {
            name  = "APP_HOST"
            value = "127.0.0.1"
          }
        ]
        # Where we map our volume. Our proxy expects the data from location /vol/static
        # This is how we share data between the app and the proxy
        mountPoints = [
          {
            readOnly      = true
            containerPath = "/vol/static"
            sourceVolume  = "static"
          }
        ]

        # Log configuration for the container
        # This tells ecs where to store the logs of the container. Which is cloudwatch
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name # Name of the log group
            awslogs-region        = data.aws_region.current.name                # Region where the logs are going to be stored
            awslogs-stream-prefix = "proxy"                                     # This is how we split different logs from different containers to different streams
          }
        }
      }
    ]
  )
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
