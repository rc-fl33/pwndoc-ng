resource "aws_ebs_volume" "mongo_data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${var.project_name}-mongo-data"
  }
}

resource "aws_volume_attachment" "mongo_data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.mongo_data.id
  instance_id = aws_instance.app.id
}

# EBS snapshot lifecycle policy — daily snapshots, retain 7 days
resource "aws_dlm_lifecycle_policy" "mongo_backup" {
  description        = "Daily EBS snapshots for MongoDB data"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  tags = {
    Name = "${var.project_name}-mongo-backup-policy"
  }

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Name = "${var.project_name}-mongo-data"
    }

    schedule {
      name = "daily-snapshot"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        Project         = var.project_name
        Environment     = var.environment
        ManagedBy       = "terraform"
      }

      copy_tags = true
    }
  }
}

resource "aws_iam_role" "dlm" {
  name_prefix = "${var.project_name}-dlm-"

  tags = {
    Name = "${var.project_name}-dlm-role"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "dlm.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"

}
