resource "aws_iam_policy" "main" {
  name        = "${var.component}-${var.env}"
  path        = "/"
  description = "${var.component}-${var.env}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            /* "Resource": [
                "arn:aws:ssm:us-east-1:${data.aws_caller_identity.account.account_id}:parameter/${var.env}.${var.component}*",
                "arn:aws:ssm:us-east-1:${data.aws_caller_identity.account.account_id}:parameter/${var.env}.docdb.*",
                "arn:aws:ssm:us-eat-1:${data.aws_caller_identity.account.account_id}:parameter/${var.env}.elasticache.*"
                # @here - docdb access elasticache params nad vice versa, We need to limit access permission
                # as they are unwanted for other components. This will cover in Session-48
            ] */
            "Resource": [
              for k in local.parameters : "arn:aws:ssm:us-east-1:${data.aws_caller_identity.account.account_id}:parameter/${var.env}.${k}.*"

            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role" "main" {
  name = "${var.component}-${var.env}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    var.tags,
    { Name = "${var.component}-${var.env}" }
  )
}

#this instance profile need to be added to template in main.tf
resource "aws_iam_instance_profile" "main" {
  name = "${var.component}-${var.env}"
  role = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "role-policy-attach" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}