#################################################################
# Create IAM user and policies for Continuous deploy (CD) account
#################################################################

# recourse creates a resource in aws

# Creation of user for CD account
resource "aws_iam_user" "cd" {
  name = "recipe-app-api-cd"
}

# Creation of access key for the user
resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name # This creates access key for machine to machine communication
}

#########################################################
# Policy for Teraform backend to S3 and DynamoDB access #
#########################################################

# Generates something we can use in a resource

# Define the policy document
data "aws_iam_policy_document" "tf_backend" {
  # Allow the ListBucket permission on this specific bucket
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf_state_bucket}"]
  }

  # Allow the GetObject, PutObject, and DeleteObject permissions on the objects in this bucket
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy/*",    # This is the path to the state file for deploy
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env/*" # This is for the deployed account
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:us-east-2:*:table/${var.tf_state_lock_table}"]
  }
}

# Create policy document out of the data defined above
resource "aws_iam_policy" "tf_backend" {
  name        = "${aws_iam_user.cd.name}-tf-s3-dynamodb"
  description = "Allow user to use S3 and DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend.json
}

# Link the policy to the user
resource "aws_iam_user_policy_attachment" "tf_backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.tf_backend.arn
}


#########################
# Policy for ECR access #
#########################

# Define the policy document
# Data is the keyword to define something we can use in a resource
data "aws_iam_policy_document" "ecr" {
  statement {
    # Allows to get auth token on all resources, so we can do docker commands
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    # Allows everything that is needed for us to push to the ECR repositories
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]

    # We specify the resources we want to allow these actions on
    # Arn is Amazon Resource Name
    resources = [
      aws_ecr_repository.app.arn,
      aws_ecr_repository.proxy.arn,
    ]
  }
}

# Create policy document out of the data defined above
resource "aws_iam_policy" "ecr" {
  name        = "${aws_iam_user.cd.name}-ecr"
  description = "Allow user to manage ECR resources"
  policy      = data.aws_iam_policy_document.ecr.json # Creates resource in aws
}

# Attach the policy to the CD user
resource "aws_iam_user_policy_attachment" "ecr" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.ecr.arn
}
