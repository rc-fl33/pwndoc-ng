resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    git_repo_url        = var.git_repo_url
    git_branch          = var.git_branch
    mongo_root_password = var.mongo_root_password
    mongo_app_password  = var.mongo_app_password
    jwt_secret          = var.jwt_secret
    jwt_refresh_secret  = var.jwt_refresh_secret
    domain_name         = var.domain_name
    ebs_device          = "/dev/xvdf"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}
