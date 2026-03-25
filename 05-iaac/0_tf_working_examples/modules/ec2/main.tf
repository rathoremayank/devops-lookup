resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  monitoring = true

  user_data = base64encode(var.user_data)

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "instance" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-eip"
    }
  )

  depends_on = [aws_instance.main]
}
