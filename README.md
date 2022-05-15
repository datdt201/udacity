# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create Udacity Cloud Lab [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
#### Configure environment variables
1. Login Azure from command line
`az login`
2. Create environment variables using Service Principal Details provided by Udacity.
Below is sample for Mac OSX:
```
export ARM_TENANT_ID=[Tenant Id]
export ARM_CLIENT_ID=[Application Id]
export ARM_CLIENT_SECRET=[Secret Key]
export ARM_SUBSCRIPTION_ID=[Subscription Id]
```

#### Using Azure CLI to create policy that requires tag when create Azure resource
1. Create policy definition
`az policy definition create --name tagging-policy --rules az-policy-tag-require.json`
2. Assign created definition to subscription (replace with your subscription id)
`az policy assignment create --name tagging-policy --policy tagging-policy --scope /subscriptions/$ARM_SUBSCRIPTION_ID`
3. Verify created assignment
`az policy assignment list`

#### Using Packer to create web server image
1. Build image
`packer build server.json`
2. Verify created image
`az image list`

#### Using Terraform to provision web server with load balancer, virtual machines
1. Initialize for Terraform
`terraform init`
2. Customize variables in `vars.tf` if needed
3. Apply Terraform
`terraform apply`

### Output
If Terraform apply command is succesful, it will output load balancer URL.
E.g. `lb_url = "http://20.225.101.116:80"`
Open that URL on browser, if server is up, you will see Welcome page of nginx.
