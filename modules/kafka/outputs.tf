output "kafka_instance_id" {
  description = "Kafka EC2 instance ID"
  value       = aws_instance.kafka.id
}

output "kafka_public_ip" {
  description = "Public IP address of Kafka EC2"
  value       = aws_instance.kafka.public_ip
}

output "kafka_private_ip" {
  description = "Private IP address of Kafka EC2"
  value       = aws_instance.kafka.private_ip
}

output "control_center_url" {
  description = "Confluent Control Center URL"
  value       = "http://${aws_instance.kafka.public_ip}:9021"
}