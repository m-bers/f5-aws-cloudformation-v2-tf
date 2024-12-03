# F5 BIG-IP AWS CloudFormation Templates - Terraform module

This module wraps the official F5 [failover](https://github.com/F5Networks/f5-aws-cloudformation-v2/tree/main/examples/failover) CloudFormation in a terraform module. 

## Instructions:
1. Clone this repository:

```bash
git clone --recurse-submodules https://github.com/m-bers/f5-aws-cloudformation-v2-tf.git
cd f5-aws-cloudformation-v2-tf
```

2. Create a `terraform.tfvars` file with your parameters for the template--use [this](https://github.com/F5Networks/f5-aws-cloudformation-v2/tree/main/examples/failover#template-input-parameters) as a guide. 

Make sure you set `s3BucketRegion` to something other than `us-east-1` if you are deploying in a different region.

> [!NOTE] 
> In order to allow you to fully edit the source CloudFormation template, this project takes over several of the input parameters if you don't supply your own value:

* bigIpInstanceProfile
* s3BucketName
* bigIpRuntimeInitConfig01
* bigIpRuntimeInitConfig02

The ability to supply your own values has been retained for compatibility with the original template. But you shouldn't include these parameters unless you want to set up bucket access yourself or if you have another place to host the template files. 

> [!NOTE] 
> In addition to the parameters for the CloudFormation template, there are two additional variables you can set:
> * `big_ip_ssh_public_key`
> * `big_ip_password`

In the original template, you had to create the SSH key in EC2 and supply the name of the object. In this module, you can still do that if you wish by supplying `sshKey` as an input parameter, but you will need to ensure the key is created in AWS first. Otherwise you can specify the location of an existing public key file in `big_ip_ssh_public_key`, such as `~/.ssh/id_rsa.pub`, without setting `sshKey`. 

Similarly, you can use this module to set your own administrator password, rather than having to create an AWS secret first or use the autogenerated password from the CloudFormation template. Set `big_ip_password` if you want to set your own password, or alternatively set `bigIpSecretArn` if you want to use an existing secret in AWS. 

The original CloudFormation template requires that you set `restrictedSrcAddressMgmt` and `restrictedSrcAddressApp`. By default, this module will automatically retrieve your client's public IP address and use that. You can override this behavior by setting the parameters to another value. 

3. (optional) Make edits to the CloudFormation template before deployment.

For example, the AMI IDs for the `application` stack are broken. This module allows you to override them with your own values. e.g.:

**From:**
```yaml
# f5-aws-cloudformation-v2/examples/modules/application/application.yaml
Mappings:
  imageRegionMap:
    us-east-1:
      AMI: ami-00543d76373f96fe7
```
**To:**
```yaml
# f5-aws-cloudformation-v2/examples/modules/application/application.yaml
Mappings:
  imageRegionMap:
    us-east-1:
      AMI: ami-0a73e96a849c232cc
```

4. Deploy the module:

```bash
terraform plan -out "tfplan"
terraform apply "tfplan"
```

## To Do:

* Restrict S3 access to `bigIpInstanceProfile`
* Set up the `failover-existing-network` template
* Split up declarative onboarding for more consistency
* Git tutorial for maintaining changes to both repo and submodule. 