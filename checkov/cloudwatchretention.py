from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class CloudwatchRetention(BaseResourceCheck):
    def __init__(self):
        name = "Ensure Cloudwatch logs group has retention days specified"
        id = "CKV_AWS_999"
        supported_resources = ['aws_cloudwatch_log_group']
        categories = [CheckCategories.LOGGING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        if "retention_in_days" in conf.keys():
            if conf["retention_in_days"][0] == "":
                return CheckResult.FAILED
            return CheckResult.PASSED
        return CheckResult.FAILED

check = CloudwatchRetention()
