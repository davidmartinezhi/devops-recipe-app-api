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
    resources = ["arn:aws:dynamodb:*:*:table/${var.tf_state_lock_table}"]
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
