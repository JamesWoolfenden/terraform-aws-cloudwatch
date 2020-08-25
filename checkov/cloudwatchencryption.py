from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class CloudwatchEncryption(BaseResourceCheck):
    def __init__(self):
        name = "Ensure Cloudwatch logs are encrypted - kms_key_id is set"
        id = "CKV_AWS_9999"
        supported_resources = ['aws_cloudwatch_log_group']
        categories = [CheckCategories.LOGGING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        if "kms_key_id" in conf.keys():
            if conf["kms_key_id"][0] == "":
                return CheckResult.FAILED
            return CheckResult.PASSED
        return CheckResult.FAILED


check = CloudwatchEncryption()
