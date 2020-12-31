# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
Your company's development team has created an application that they need deployed to Azure. The application is self-contained, but they need the infrastructure to deploy it in a customizable way based on specifications provided at build time, with an eye toward scaling the application for use in a CI/CD pipeline.

Although we’d like to use Azure App Service, management has told us that the cost is too high for a PaaS like that and wants us to deploy it as pure IaaS so we can control cost. Since they expect this to be a popular service, it should be deployed across multiple virtual machines.

To support this need and minimize future work, we will use Packer to create a server image, and Terraform to create a template for deploying a scalable cluster of servers—with a load balancer to manage the incoming traffic. We’ll also need to adhere to security practices and ensure that our infrastructure is secure



### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
### Azure Login
Run: ```$ az login```
#### Run packer
In order to build the image you need to:
1. Create Resource group on azure with the name packer-rg
2. Create credentials for packer script. On azure cli run: ```$ az ad sp create-for-rbac -n "packer" ```
to get the credentials
3. Set env variables(ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID)
4. On packer folder Run: ```$ packer build server.json```
#### Run terraform
In order to build the infrastructure with terraform you need to:
1. Run: ```$ terraform init```
2. Run: ```$ terraform apply```
3. Provide your tenant id
4. Provide your password for Vms
5. Provide your user for vms
#### Customize terraform script with vars
You can customize your script using vars
For instance, run: ``` terraform apply -var instance_count=3 ``` to improve the numbers of Vms
To see all variables, access the file vars.tf
