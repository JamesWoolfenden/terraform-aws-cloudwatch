# terraform-aws-cloudwatch

[![Build Status](https://github.com/JamesWoolfenden/terraform-aws-cloudwatch/workflows/Verify/badge.svg?branch=main)](https://github.com/JamesWoolfenden/terraform-aws-cloudwatch)
[![Latest Release](https://img.shields.io/github/release/JamesWoolfenden/terraform-aws-cloudwatch.svg)](https://github.com/JamesWoolfenden/terraform-aws-cloudwatch/releases/latest)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/JamesWoolfenden/terraform-aws-cloudwatch.svg?label=latest)](https://github.com/JamesWoolfenden/terraform-aws-cloudwatch/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.14.0-blue.svg)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

This ia a Terraform module to provision a secure Terraform S3 bucket. It also has a provisioning test included in its' Github actions so you can be sure each labelled version works.

---

It's 100% Open Source and licensed under the [APACHE2](LICENSE).

## Usage

Include this repository as a module in your existing Terraform code:

```terraform
module "cloudwatch" {
  source         = "JamesWoolfenden/cloudwatch/aws"
  version        = "0.4.0"
  log_group_name = "/aws/my-application"
  kms_key_id     = aws_kms_key.logs.arn
}
```

### KMS key requirements

`kms_key_id` is mandatory, and CloudWatch Logs cannot use a key whose policy does
not grant it access. Supplying a key ARN that lacks this grant fails at apply time
with an opaque `InvalidParameterException`, not at plan time.

The key policy must allow the `logs.<region>.amazonaws.com` service principal, and
that grant should be conditioned on the log-group encryption context — an
unconditioned grant lets the CloudWatch Logs service use your key on behalf of a
log group in *any* AWS account:

```terraform
resource "aws_kms_key" "logs" {
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.region}.amazonaws.com" }
        Action    = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
        Resource  = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })
}
```

See [example/examplea](example/examplea) for a complete working configuration.

### Metric filters and alarms

`metric_filters` turns log patterns into CloudWatch metrics, and each entry may
optionally declare an `alarm` block to alert on the extracted metric:

```terraform
module "cloudwatch" {
  source         = "JamesWoolfenden/cloudwatch/aws"
  log_group_name = "/aws/my-application"
  kms_key_id     = aws_kms_key.logs.arn

  metric_filters = {
    errors = {
      pattern = "ERROR"
      metric_transformation = {
        name      = "AppErrorCount"
        namespace = "MyApp/Logs"
        value     = "1"
      }
      alarm = {
        threshold     = 5
        description   = "More than five ERROR lines in five minutes"
        alarm_actions = [aws_sns_topic.alerts.arn]
      }
    }
  }
}
```

### Subscription filters

`subscription_filters` forwards log events to a Lambda function, Kinesis stream
or Firehose delivery stream:

```terraform
subscription_filters = {
  to_opensearch = {
    destination_arn = aws_kinesis_firehose_delivery_stream.logs.arn
    filter_pattern  = ""
    role_arn        = aws_iam_role.cwl_to_firehose.arn
  }
}
```

Both features require `log_group_class = "STANDARD"`; the module enforces this
with a resource precondition rather than letting it fail at apply time.

Tags are not a module input — the log group inherits whatever the `aws` provider's
`default_tags` block sets.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_metric_filter.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_log_subscription_filter.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_cloudwatch_metric_alarm.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_deletion_protection_enabled"></a> [deletion\_protection\_enabled](#input\_deletion\_protection\_enabled) | Prevent the log group being deleted. Unlike lifecycle.prevent\_destroy this is enforced by AWS, so it still applies if the resource block is removed. Set false for ephemeral log groups that CI needs to destroy | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ARN of the KMS key used to encrypt the log group data | `string` | n/a | yes |
| <a name="input_log_group_class"></a> [log\_group\_class](#input\_log\_group\_class) | Log group class. INFREQUENT\_ACCESS costs roughly half the ingestion price of STANDARD but does not support metric filters, subscription filters or Live Tail | `string` | `"STANDARD"` | no |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | Name of the CloudWatch log group to create | `string` | n/a | yes |
| <a name="input_metric_filters"></a> [metric\_filters](#input\_metric\_filters) | Metric filters to create on the log group, keyed by filter name. Set the optional alarm object to also create a CloudWatch alarm on the extracted metric | <pre>map(object({<br/>    pattern = string<br/>    metric_transformation = object({<br/>      name          = string<br/>      namespace     = string<br/>      value         = string<br/>      default_value = optional(string)<br/>      unit          = optional(string)<br/>    })<br/>    alarm = optional(object({<br/>      threshold           = number<br/>      actions_enabled     = optional(bool, true)<br/>      comparison_operator = optional(string, "GreaterThanOrEqualToThreshold")<br/>      evaluation_periods  = optional(number, 1)<br/>      period              = optional(number, 300)<br/>      statistic           = optional(string, "Sum")<br/>      description         = optional(string)<br/>      alarm_actions       = optional(list(string), [])<br/>      ok_actions          = optional(list(string), [])<br/>      treat_missing_data  = optional(string, "notBreaching")<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_retention"></a> [retention](#input\_retention) | Log retention in days | `number` | `365` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | Retain the log group in AWS when it is removed from Terraform state, rather than deleting it | `bool` | `false` | no |
| <a name="input_subscription_filters"></a> [subscription\_filters](#input\_subscription\_filters) | Subscription filters to create on the log group, keyed by filter name, forwarding log events to a Lambda function, Kinesis stream or Firehose delivery stream | <pre>map(object({<br/>    destination_arn = string<br/>    filter_pattern  = string<br/>    role_arn        = optional(string)<br/>    distribution    = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the CloudWatch log group |
| <a name="output_log_group_class"></a> [log\_group\_class](#output\_log\_group\_class) | The class of the CloudWatch log group |
| <a name="output_metric_alarm_arns"></a> [metric\_alarm\_arns](#output\_metric\_alarm\_arns) | ARNs of the CloudWatch alarms created from the metric filters, keyed by filter key |
| <a name="output_metric_filter_names"></a> [metric\_filter\_names](#output\_metric\_filter\_names) | Names of the metric filters created on the log group, keyed by filter key |
| <a name="output_name"></a> [name](#output\_name) | The name of the CloudWatch log group |
| <a name="output_retention_in_days"></a> [retention\_in\_days](#output\_retention\_in\_days) | The retention period in days applied to the log group |
| <a name="output_subscription_filter_names"></a> [subscription\_filter\_names](#output\_subscription\_filter\_names) | Names of the subscription filters created on the log group, keyed by filter key |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Policy

This is the policy required to build this project:

<!-- BEGINNING OF PRE-COMMIT-PIKE DOCS HOOK -->
The Terraform resource required is:

```golang
# apply role — full permissions for terraform apply
resource "aws_iam_policy" "terraform_pike" {
  name_prefix = "terraform_pike"
  path        = "/"
  description = "Pike Autogenerated policy from IAC"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:ListTagsForResource",
                "cloudwatch:PutMetricAlarm"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "logs:AssociateKmsKey",
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DeleteMetricFilter",
                "logs:DeleteRetentionPolicy",
                "logs:DeleteSubscriptionFilter",
                "logs:DescribeLogGroups",
                "logs:DescribeMetricFilters",
                "logs:DescribeSubscriptionFilters",
                "logs:DisassociateKmsKey",
                "logs:ListTagsForResource",
                "logs:ListTagsLogGroup",
                "logs:PutMetricFilter",
                "logs:PutRetentionPolicy",
                "logs:PutSubscriptionFilter"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
})
}

# plan role — read-only permissions for terraform plan
resource "aws_iam_policy" "terraform_pike_plan" {
  name_prefix = "terraform_pike_plan"
  path        = "/"
  description = "Pike Autogenerated policy from IAC"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeSubscriptionFilters"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
})
}


```
<!-- END OF PRE-COMMIT-PIKE DOCS HOOK -->

## Related Projects

Check out these related projects.

- [terraform-aws-statebucket](https://github.com/jameswoolfenden/terraform-aws-statebucket) - Terraform s3 state buckets

## Help

**Got a question?**

File a GitHub [issue](https://github.com/JamesWoolfenden/terraform-aws-3/issues).

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/JamesWoolfenden/terraform-aws-3/issues) to report any bugs or file feature requests.

## Copyrights

Copyright © 2019-2026 James Woolfenden

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
distributed with this work for additional information
regarding copyright ownership. The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

<https://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the License for the
specific language governing permissions and limitations
under the License.

### Contributors

[![James Woolfenden][jameswoolfenden_avatar]][jameswoolfenden_homepage]<br/>[James Woolfenden][jameswoolfenden_homepage]

[jameswoolfenden_homepage]: https://github.com/jameswoolfenden
[jameswoolfenden_avatar]: https://github.com/jameswoolfenden.png?size=150
