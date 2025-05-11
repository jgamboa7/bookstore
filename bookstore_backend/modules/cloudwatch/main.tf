resource "aws_cloudwatch_metric_alarm" "upload_error_alarm" {
  alarm_name          = "lambda-upload-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers if there is at least 1 error in Lambda in 1 minute"
  dimensions = {
    FunctionName = var.lambda_upload_name 
  }
  alarm_actions = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "download_error_alarm" {
  alarm_name          = "lambda-download-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers if there is at least 1 error in Lambda in 1 minute"
  dimensions = {
    FunctionName = var.lambda_download_name 
  }
  alarm_actions = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "search_error_alarm" {
  alarm_name          = "lambda-search-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers if there is at least 1 error in Lambda in 1 minute"
  dimensions = {
    FunctionName = var.lambda_search_name 
  }
  alarm_actions = [var.sns_arn]
}
