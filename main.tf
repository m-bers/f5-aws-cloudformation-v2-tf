provider "aws" {
  region     = var.s3BucketRegion
}

# --- locals ---

locals {
  # Parameter overrides
  bigIpInstanceProfile     = var.bigIpInstanceProfile != null ? var.bigIpInstanceProfile : (aws_cloudformation_stack.bigip_access[0].outputs.bigIpInstanceProfile)
  bigIpRuntimeInitConfig01 = var.bigIpRuntimeInitConfig01 != null ? var.bigIpRuntimeInitConfig01 : "${local.s3_url}/bigip-runtime-init-config-01.yaml"
  bigIpRuntimeInitConfig02 = var.bigIpRuntimeInitConfig02 != null ? var.bigIpRuntimeInitConfig02 : "${local.s3_url}/bigip-runtime-init-config-02.yaml"
  cfeS3Bucket              = var.cfeS3Bucket != null ? var.cfeS3Bucket : "${local.uniqueString}-bigip-high-availability-solution"
  bigIpSecretArn           = var.bigIpSecretArn != null ? var.bigIpSecretArn : aws_secretsmanager_secret.big_ip_secret.arn
  restrictedSrcAddressMgmt = var.restrictedSrcAddressMgmt != null ? var.restrictedSrcAddressMgmt : "${data.http.my_public_ip.response_body}/32"
  restrictedSrcAddressApp  = var.restrictedSrcAddressApp != null ? var.restrictedSrcAddressApp : "${data.http.my_public_ip.response_body}/32"
  s3BucketName             = var.s3BucketName != null ? var.s3BucketName : aws_s3_bucket.bigip_failover_cft.bucket
  sshKey                   = var.sshKey != null ? var.sshKey : aws_key_pair.bigip_failover_ssh_key[0].key_name
  uniqueString             = var.uniqueString != null ? var.uniqueString : "${random_string.uniqueString.result}"
  # Other locals
  s3_url = "https://${local.bigip_failover_cft}.s3.${var.s3BucketRegion}.amazonaws.com"
  bigip_failover_cft = "${local.uniqueString}-bigip-failover-cft"

  common_tags = {
    application = var.application
    cost        = var.cost
    environment = var.environment
    group       = var.group
    owner       = var.owner
  }

  bigip_runtime_configs = tomap({
    config_01 = {
      key         = "bigip-runtime-init-config-01.yaml"
      do_end_path = "${local.s3_url}/templates/do-end-01.yaml"
      remote_host = null
    },
    config_02 = {
      key         = "bigip-runtime-init-config-02.yaml"
      do_end_path = "${local.s3_url}/templates/do-end-02.yaml"
      remote_host = file("${path.module}/templates/remote.yaml")
    }
  })
}

# --- modules ---

module "f5_automation_toolchain" {
  source         = "./modules/f5_automation_toolchain"
  for_each       = var.f5_automation_toolchain
  type           = each.key  # as3, do, cf
  release_version = each.value
}

# --- resources ---

resource "random_string" "uniqueString" {
  length  = 8
  special = false
  upper   = false
  numeric  = false
}

resource "aws_s3_bucket_ownership_controls" "bigip_failover_cft" {
  bucket = aws_s3_bucket.bigip_failover_cft.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket" "bigip_failover_cft" {
  bucket        = local.bigip_failover_cft
  tags          = local.common_tags
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bigip_failover_cft" {
  bucket = aws_s3_bucket.bigip_failover_cft.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bigip_failover_cft" {
  depends_on = [aws_s3_bucket_ownership_controls.bigip_failover_cft]
  bucket     = aws_s3_bucket.bigip_failover_cft.id
  acl        = "public-read"
}

resource "aws_s3_object" "bigip_failover_cft" {
  depends_on = [aws_s3_bucket_public_access_block.bigip_failover_cft]
  for_each   = fileset("${path.module}/${var.artifactLocation}", "**/*")
  bucket     = aws_s3_bucket.bigip_failover_cft.id
  key        = "${var.artifactLocation}${each.value}"
  source     = "${path.module}/${var.artifactLocation}${each.value}"
  etag       = filemd5("${path.module}/${var.artifactLocation}${each.value}")
}

resource "aws_s3_object" "template_files" {
  depends_on = [aws_s3_bucket_public_access_block.bigip_failover_cft]
  for_each   = fileset("${path.module}/templates", "**/*")

  bucket = aws_s3_bucket.bigip_failover_cft.id
  key    = "templates/${each.value}"
  source = "${path.module}/templates/${each.value}"
  etag   = filemd5("${path.module}/templates/${each.value}")
}

resource "local_file" "bigip_runtime_init_config" {
  for_each   = local.bigip_runtime_configs
  content = templatefile("${path.module}/templates/runtime-init-conf-3nic-payg-instance-with-app.tpl", {
    DO_START_PATH = "${local.s3_url}/templates/do.yaml"
    DO_END_PATH   = each.value.do_end_path
    DO_VERSION    = var.f5_automation_toolchain["do"]
    DO_HASH       = module.f5_automation_toolchain["do"].sha256_checksum
    AS3_PATH      = "${local.s3_url}/templates/as3.yaml"
    AS3_VERSION   = var.f5_automation_toolchain["as3"]
    AS3_HASH      = module.f5_automation_toolchain["as3"].sha256_checksum
    CF_PATH       = "${local.s3_url}/templates/cf.yaml"
    CF_VERSION    = var.f5_automation_toolchain["cf"]
    CF_HASH       = module.f5_automation_toolchain["cf"].sha256_checksum
    REMOTE_HOST   = each.value.remote_host != null ? each.value.remote_host : ""
  })
  filename = "${path.module}/output/${each.value.key}"
}

resource "aws_s3_object" "bigip_runtime_init_config" {
  depends_on = [aws_s3_bucket_public_access_block.bigip_failover_cft, local_file.bigip_runtime_init_config]
  for_each   = local.bigip_runtime_configs

  bucket = aws_s3_bucket.bigip_failover_cft.id
  key    = each.value.key
  content = local_file.bigip_runtime_init_config[each.key].content
  etag = md5(local_file.bigip_runtime_init_config[each.key].content)
}

resource "aws_s3_bucket_policy" "bigip_failover_policy" {
  bucket = aws_s3_bucket.bigip_failover_cft.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.bigip_failover_cft.arn,
          "${aws_s3_bucket.bigip_failover_cft.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_key_pair" "bigip_failover_ssh_key" {
  count = var.sshKey == null ? 1 : 0
  key_name   = "bigip_failover_ssh_key-${random_string.uniqueString.result}"
  public_key = file(var.big_ip_ssh_public_key)
  tags       = local.common_tags
}

resource "aws_secretsmanager_secret" "big_ip_secret" {
  name = "${local.uniqueString}-bigIpSecret"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "big_ip_secret_version" {
  secret_id     = aws_secretsmanager_secret.big_ip_secret.id
  secret_string = var.big_ip_password
}

resource "aws_cloudformation_stack" "bigip_access" {
  count        = var.bigIpInstanceProfile == null ? 1 : 0
  depends_on   = [aws_s3_object.bigip_failover_cft]
  name         = "bigipAccess-${local.uniqueString}"
  template_url = "${local.s3_url}/${var.artifactLocation}modules/access/access.yaml"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  tags         = local.common_tags

  parameters = merge(local.common_tags, {
    cfeTag       = var.cfeTag
    secretArn    = local.bigIpSecretArn
    s3Bucket     = local.cfeS3Bucket
    solutionType = "failover"
    uniqueString = local.uniqueString
  })
}

resource "aws_cloudformation_stack" "bigip_failover" {
  depends_on = [
    aws_s3_object.bigip_failover_cft,
    aws_s3_bucket_policy.bigip_failover_policy
  ]
  name         = "bigipFailover-${local.uniqueString}"
  template_url = "${local.s3_url}/${var.artifactLocation}failover/failover.yaml"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  tags = local.common_tags

  parameters = merge(local.common_tags, {
    allowUsageAnalytics        = var.allowUsageAnalytics
    appDockerImageName         = var.appDockerImageName
    artifactLocation           = var.artifactLocation
    bigIpCustomImageId         = var.bigIpCustomImageId
    bigIpHostname01            = var.bigIpHostname01
    bigIpHostname02            = var.bigIpHostname02
    bigIpImage                 = var.bigIpImage
    bigIpInstanceProfile       = local.bigIpInstanceProfile
    bigIpInstanceType          = var.bigIpInstanceType
    bigIpLicenseKey01          = var.bigIpLicenseKey01
    bigIpLicenseKey02          = var.bigIpLicenseKey02
    bigIpPeerAddr              = var.bigIpPeerAddr
    bigIpRuntimeInitConfig01   = local.bigIpRuntimeInitConfig01
    bigIpRuntimeInitConfig02   = local.bigIpRuntimeInitConfig02
    bigIpRuntimeInitPackageUrl = var.bigIpRuntimeInitPackageUrl
    cfeS3Bucket                = local.cfeS3Bucket
    cfeTag                     = var.cfeTag
    cfeVipTag                  = var.cfeVipTag
    bigIpExternalSelfIp01      = var.bigIpExternalSelfIp01
    bigIpExternalSelfIp02      = var.bigIpExternalSelfIp02
    bigIpExternalVip01         = var.bigIpExternalVip01
    bigIpExternalVip02         = var.bigIpExternalVip02
    bigIpInternalSelfIp01      = var.bigIpInternalSelfIp01
    bigIpInternalSelfIp02      = var.bigIpInternalSelfIp02
    bigIpMgmtAddress01         = var.bigIpMgmtAddress01
    bigIpMgmtAddress02         = var.bigIpMgmtAddress02
    bigIpSecretArn             = local.bigIpSecretArn
    numAzs                     = var.numAzs
    numSubnets                 = var.numSubnets
    provisionExampleApp        = var.provisionExampleApp
    provisionPublicIpMgmt      = var.provisionPublicIpMgmt
    restrictedSrcAddressMgmt   = local.restrictedSrcAddressMgmt
    restrictedSrcAddressApp    = local.restrictedSrcAddressApp
    s3BucketName               = local.s3BucketName
    s3BucketRegion             = var.s3BucketRegion
    sshKey                     = local.sshKey
    subnetMask                 = var.subnetMask
    uniqueString               = local.uniqueString
    vpcCidr                    = var.vpcCidr
  })
}

# --- data sources ---

data "aws_iam_instance_profile" "bigip_instance_profile" {
  count = var.bigIpInstanceProfile == null ? 1 : 0
  name = aws_cloudformation_stack.bigip_access[0].outputs["bigIpInstanceProfile"]
}

data "aws_iam_role" "bigip_instance_role" {
  count = var.bigIpInstanceProfile == null ? 1 : 0
  name = data.aws_iam_instance_profile.bigip_instance_profile[0].role_name
}

data "http" "my_public_ip" {
  url = "https://ipinfo.io/ip"
}

# --- outputs ---
output "bigip_failover" {
  value = aws_cloudformation_stack.bigip_failover.outputs
}