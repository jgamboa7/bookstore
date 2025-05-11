resource "aws_sns_topic" "alerts" {
  name = "bookstore-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "josemiguelgamboarondon@gmail.com"
}
