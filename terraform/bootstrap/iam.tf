resource "aws_iam_policy" "terraform_admin_policy" {
  name   = "terraform-admin-policy"
  policy = file(var.policy_file_path)
}
