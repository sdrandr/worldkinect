########################################
# Terraform Admin Role (for CI/CD OIDC)
########################################

resource "aws_iam_role" "terraform_admin" {
  name = "terraform-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::891377181070:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:sdrandr/worldkinect:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

########################################
# Attach AdministratorAccess (for now)
########################################

resource "aws_iam_role_policy_attachment" "terraform_admin_adminaccess" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy" "terraform_admin_policy" {
  name   = "terraform-admin-policy"
  policy = file("${path.module}/policies/iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "terraform_admin_policy_attach" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.terraform_admin_policy.arn
}
