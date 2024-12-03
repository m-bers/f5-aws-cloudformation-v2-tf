
variable "big_ip_password" {}

# F5 Runtime Init

variable "f5_automation_toolchain" {
  default = {
    as3 = "3.53.0"
    do  = "1.44.0"
    cf  = "2.1.2"
  }
}

# CloudFormation Parameters

variable "allowUsageAnalytics" {
  description = "This deployment can send anonymous statistics to F5 to help us determine how to improve our solutions. If you select **false** statistics are not sent."
  default     = "true"
}

variable "appDockerImageName" {
  description = "Application docker image name"
  default     = "f5devcentral/f5-demo-app:latest"
}

variable "application" {
  description = "Application Tag."
  default     = "f5app"
}

variable "artifactLocation" {
  description = "The path in the S3Bucket where the modules folder is located. Can include numbers, lowercase letters, uppercase letters, hyphens (-), and forward slash (/)."
  default     = "f5-aws-cloudformation-v2/examples/"
}

variable "bigIpCustomImageId" {
  description = "Provide BIG-IP AMI ID you wish to deploy."
  default     = ""
}

variable "bigIpHostname01" {
  description = "Supply the hostname you would like to use for the BIG-IP instance. The hostname must contain fewer than 63 characters."
  default     = "failover01.local"
}

variable "bigIpHostname02" {
  description = "Supply the hostname you would like to use for the BIG-IP instance. The hostname must contain fewer than 63 characters."
  default     = "failover02.local"
}

variable "bigIpImage" {
  description = "F5 BIG-IP market place image"
  default     = "*17.1.1-0.2.6**PAYG-Best Plus 25Mbps*"
}

variable "bigIpInstanceProfile" {
  description = "Enter the name of an existing IAM instance profile with applied IAM policy to be associated to the BIG-IP virtual machine(s). Leave default to create a new instance profile."
  default     = null
}

variable "bigIpInstanceType" {
  description = "Enter valid instance type."
  default     = "m5.xlarge"
}

variable "bigIpLicenseKey01" {
  description = "Supply the F5 BYOL license key for BIG-IP instance 01. Leave this parameter blank if deploying the PAYG solution."
  default     = ""
}

variable "bigIpLicenseKey02" {
  description = "Supply the F5 BYOL license key for BIG-IP instance 02. Leave this parameter blank if deploying the PAYG solution."
  default     = ""
}

variable "bigIpPeerAddr" {
  description = "Provide the static address of the remote peer used for clustering. In this failover solution, clustering is initiated from the second instance (02) to the first instance (01) so you would provide the first instances Self IP address."
  default     = "10.0.1.11"
}

variable "bigIpRuntimeInitConfig01" {
  description = "REQUIRED - Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format to use for f5-bigip-runtime-init configuration."
  default     = null
}

variable "bigIpRuntimeInitConfig02" {
  description = "REQUIRED - Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format to use for f5-bigip-runtime-init configuration."
  default     = null
}

variable "bigIpRuntimeInitPackageUrl" {
  description = "URL for BIG-IP Runtime Init package."
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run"
}

variable "cfeS3Bucket" {
  description = "Supply a unique name for a CFE S3 bucket created and used by Cloud Failover Extension."
  default     = null
}

variable "cfeTag" {
  description = "Cloud Failover deployment tag value."
  default     = "bigip_high_availability_solution"
}

variable "cfeVipTag" {
  description = "Cloud Failover VIP tag value; provides private ip addresses to be assigned to VIP public ip."
  default     = "10.0.0.101,10.0.4.101"
}

variable "cost" {
  description = "Cost Center Tag."
  default     = "f5cost"
}

variable "environment" {
  description = "Environment Tag."
  default     = "f5env"
}

variable "bigIpExternalSelfIp01" {
  description = "External Private IP Address for BIGIP instance A."
  default     = "10.0.0.11"
}

variable "bigIpExternalSelfIp02" {
  description = "External Private IP Address for BIGIP instance B."
  default     = "10.0.4.11"
}

variable "bigIpExternalVip01" {
  description = "External Secondary Private IP Address for BIGIP instance A."
  default     = "10.0.0.101"
}

variable "bigIpExternalVip02" {
  description = "External Secondary Private IP Address for BIGIP instance B."
  default     = "10.0.4.101"
}

variable "group" {
  description = "Group Tag."
  default     = "f5group"
}

variable "bigIpInternalSelfIp01" {
  description = "Internal Private IP Address for BIGIP instance A."
  default     = "10.0.2.11"
}

variable "bigIpInternalSelfIp02" {
  description = "Internal Private IP Address for BIGIP instance B."
  default     = "10.0.6.11"
}

variable "bigIpMgmtAddress01" {
  description = "Management Private IP Address for BIGIP instance A."
  default     = "10.0.1.11"
}

variable "bigIpMgmtAddress02" {
  description = "Management Private IP Address for BIGIP instance B."
  default     = "10.0.5.11"
}

variable "bigIpSecretArn" {
  description = "The ARN of an existing AWS Secrets Manager secret where the BIG-IP password used for clustering is stored. If left empty, a secret will be created."
  default     = null
}

variable "numAzs" {
  description = "Number of Availability Zones to use in the VPC. Region must support number of availability zones entered. Min 1 Max 2."
  default     = "2"
}

variable "numNics" {
  description = "Number of interfaces to create on BIG-IP instance. Maximum of 3 allowed. Minimum of 2 allowed."
  default     = "3"
}

variable "numSubnets" {
  description = "Indicate the number of subnets to create. A minimum of 4 subnets required when provisionExampleApp = false"
  default     = "4"
}

variable "owner" {
  description = "Owner Tag."
  default     = "f5owner"
}

variable "provisionExampleApp" {
  description = "Flag to deploy the demo web application."
  default     = "true"
}

variable "provisionPublicIpMgmt" {
  description = "Whether or not to provision public IP addresses for the BIG-IP management network interfaces."
  default     = "true"
}

variable "restrictedSrcAddressMgmt" {
  description = "REQUIRED - The IP address range used to SSH and access management GUI on the EC2 instances."
  default     = null
}

variable "restrictedSrcAddressApp" {
  description = "REQUIRED - The IP address range that can be used to access web traffic (80/443) to the EC2 instances."
  default     = null
}

variable "s3BucketName" {
  description = "REQUIRED - S3 bucket name for the modules. S3 bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-)."
  default     = null
}

variable "s3BucketRegion" {
  description = "The AWS Region where the Quick Start S3 bucket (s3BucketName) is hosted. When using your own bucket, you must specify this value."
  default     = "us-east-1"
}

variable "sshKey" {
  description = "Supply the public key that will be used for SSH authentication to the BIG-IP, application, and bastion virtual machines. If left empty, one will be created."
  default     = null
}

variable "subnetMask" {
  description = "Mask for subnets. Valid values include 16-28. Note supernetting of VPC occurs based on mask provided; therefore, number of networks must be >= to the number of subnets created. Mask for subnets. Valid values include 16-28."
  default     = "24"
}

variable "uniqueString" {
  description = "Unique String used when creating object names or Tags."
  default     = null
}

variable "vpcCidr" {
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}