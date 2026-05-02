output "kafka_instance_id" {
  description = "EC2 instance ID of the Kafka instance"
  value       = aws_instance.kafka.id
}

output "kafka_public_ip" {
  description = "Public IP address of the Kafka EC2 instance"
  value       = aws_instance.kafka.public_ip
}

output "kafka_private_ip" {
  description = "Private IP address of the Kafka EC2 instance"
  value       = aws_instance.kafka.private_ip
}

output "control_center_url" {
  description = "Confluent Control Center URL"
  value       = "http://${aws_instance.kafka.public_ip}:9021"
}

output "kafka_connect_url" {
  description = "Kafka Connect REST API URL"
  value       = "http://${aws_instance.kafka.public_ip}:8083"
}

output "kafka_iam_role_arn" {
  description = "IAM Role ARN attached to the Kafka EC2 instance"
  value       = aws_iam_role.kafka_ec2.arn
}
