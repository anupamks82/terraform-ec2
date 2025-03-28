# Terraform AWS EC2 with CloudWatch Monitoring

This Terraform configuration deploys an AWS EC2 instance running a basic web server that displays a "Hello, World!". It also configures CloudWatch monitoring for CPU and memory utilization and sets up CloudWatch alarms based on those metrics. Additionally, the configuration sets up an IAM role and policy to allow the EC2 instance to communicate with CloudWatch and Systems Manager (SSM) for fetching the CloudWatch agent configuration.


## Overview

- Deploys an EC2 instance running a basic web server (`httpd`) that serves a **"Hello, World!"** message on a webpage.
- Configures security groups to allow HTTP and SSH traffic.
- Configures CloudWatch agent on the instance to monitor memory and CPU usage.
- Sets up CloudWatch alarms for both CPU and memory utilization.
- Uses AWS Systems Manager (SSM) to store CloudWatch agent configuration.
- Uses IAM roles to grant permissions for CloudWatch and Systems Manager.

## Prerequisites

Before you can deploy this configuration, make sure you have the following:

- **Terraform**: Version 1.x or higher installed and configured on your machine. You can install it from [here](https://www.terraform.io/downloads).


## Configuration Steps

### Step 1: Clone the Repository

Clone this repository to your local machine:

```bash
git clone <repository-url>
cd <repository-folder>
```

### Step 2: Configure AWS Credentials access key and secret key

### Step 3: Initialize Terraform
```bash
terraform init
```
This will download the necessary provider plugins and set up your working directory.

### Step 4: Review the Terraform Plan
```bash
terraform plan
```
Review the output to ensure everything is configured correctly.

### Step 5: Apply the Terraform Configuration
```bash
terraform apply
```
Terraform will prompt you to confirm that you want to create the resources. Type `yes` to proceed.

### Step 6: Access the EC2 Instance
```bash
http://<instance-public-ip>
```
You should see the following `Hello, World!` message.

### Step 7: CloudWatch Alarms
CloudWatch alarms are set up to monitor the following metrics:
- **CPU Utilization**: An alarm will trigger if CPU usage exceeds 85%.
- **Memory Utilization**: An alarm will trigger if memory usage exceeds 85%.

### Resources Created
The following AWS resources will be created when you apply the Terraform configuration:
- **EC2 Instance:** A web server instance running a basic HTTP service (httpd) that serves the "Hello, World!" message.
- **Security Group:** Allows HTTP (port 80) and SSH (port 22) access.
- **IAM Role and Policy:** Grants the EC2 instance permissions to interact with CloudWatch and Systems Manager.
- **CloudWatch Alarms:** Two alarms for monitoring CPU and memory usage.
- **SSM Parameter:** Stores the CloudWatch agent configuration for the EC2 instance.

### Cleanup
To destroy all the resources created by this configuration, run the following command:
```bash
terraform destroy
```
