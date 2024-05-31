# Static Website with S3, CloudFront, and Route 53 using Terraform

This repository contains the Terraform configuration for setting up a static website hosted on AWS S3, distributed via CloudFront, and managed using Route 53. This configuration allows for a custom domain and SSL certificate to allow for the site to be distributed with HTTPS.

## Project Overview

The project sets up the following infrastructure:

- **S3 Buckets**:
  - `www_site`: Hosts the static website.
  - `redirect_site`: Redirects traffic from the non-www domain to the www domain.
- **CloudFront Distributions**:
  - One distribution serves the content from `www_site`.
  - Another distribution handles the redirection from `redirect_site`.
- **Route 53**:
  - Hosted zone for managing DNS records.
  - DNS records for the www and non-www domains pointing to the CloudFront distributions.

## Prerequisites

- Terraform installed on your local machine.
- AWS CLI configured with the necessary credentials.
- An AWS account with permissions to create S3 buckets, CloudFront distributions, and Route 53 records.
- An ACM certificate for your domain in the us-east-1 region (required for CloudFront).
- A custom domain

## Setup

1. **Clone the repository**:

    ```sh
    git clone https://github.com/Ammar-Alam/skillfolio-infrastructure.git
    ```

2. **Configure Terraform variables**:

    Update the `terraform.tfvars` file with your specific values:

    ```hcl
    aws_access_key = "your-aws-access-key"
    aws_secret_key = "your-aws-secret-key"
    aws_region = "your-aws-region"
    my_domain = "yourdomain.com"
    my_certificate = "arn:aws:acm:us-east-1:123456789012:certificate/your-certificate-id"
    ```

3. **Initialize and apply Terraform configuration**:

    ```sh
    terraform init
    terraform apply
    ```

    Confirm the apply step by typing `yes` when prompted. Alternatively, run the apply command with the `--auto-approve` flag to skip confirmation.

4. **Set custom domain nameserver (if needed) **:

    If you purchased your domain from somewhere other than Route 53, you will need to go to your domain registrar and configure a custom DNS nameserver. Use the Route 53 nameservers of the hosted zone created by the Terraform script. 


## Outputs

After applying the Terraform configuration, the following outputs will be available:

- **Nameservers**: Use these nameservers to update your domain's DNS settings.
- **Buckets**: The names of the created S3 buckets.
- **Website Endpoints**: The S3 website endpoints for debugging purposes.

## Implementation Details

### S3 Buckets

- `www_site`: Configured to host a static website.
- `redirect_site`: Configured to redirect all requests to the www domain.

### CloudFront Distributions

- The distributions use the ACM certificate for HTTPS support and custom domain names.

### Route 53

- A hosted zone is created for the domain.
- DNS records are configured to point the www and non-www domains to the respective CloudFront distributions.
