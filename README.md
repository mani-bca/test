Based on the diagram, I'll create a complete Terraform implementation for an AWS serverless image resizing solution. The architecture shows an automated workflow where:

1. A user uploads an image to an S3 bucket (Bucket_1)
2. This triggers a Lambda function that resizes the image
3. The Lambda function stores the resized image in a second S3 bucket (Bucket_2)
4. The Lambda also triggers an SNS topic
5. The SNS topic sends an email notification

Here's the complete Terraform implementation using a modular approach:

## Module Files

Let me create the module files for the Lambda function, S3 buckets, and SNS topic:

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.enable_notification ? 1 : 0
  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [var.lambda_permission]
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "enable_notification" {
  description = "Whether to enable S3 bucket notifications"
  type        = bool
  default     = false
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger"
  type        = string
  default     = ""
}

variable "lambda_permission" {
  description = "Lambda permission resource to depend on"
  type        = any
  default     = null
}

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}-policy"
  description = "IAM policy for Lambda function ${var.function_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ],
      var.additional_policy_statements
    )
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_permission" "s3_permission" {
  count         = var.enable_s3_trigger ? 1 : 0
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_source_file" {
  description = "Path to the Lambda function source file"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "nodejs18.x"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "additional_policy_statements" {
  description = "Additional IAM policy statements for the Lambda function"
  type        = list(any)
  default     = []
}

variable "enable_s3_trigger" {
  description = "Whether to enable S3 bucket trigger for the Lambda function"
  type        = bool
  default     = false
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket that triggers the Lambda function"
  type        = string
  default     = ""
}

output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "s3_permission" {
  description = "The S3 permission resource"
  value       = var.enable_s3_trigger ? aws_lambda_permission.s3_permission[0] : null
}

resource "aws_sns_topic" "this" {
  name = var.topic_name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.email_addresses)
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_addresses[count.index]
}

resource "aws_lambda_permission" "sns_permission" {
  count         = var.lambda_function_arn != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "email_addresses" {
  description = "List of email addresses to subscribe to the SNS topic"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the SNS topic"
  type        = map(string)
  default     = {}
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger from SNS"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to trigger from SNS"
  type        = string
  default     = ""
}

output "topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.this.name
}

const AWS = require('aws-sdk');
const sharp = require('sharp');
const s3 = new AWS.S3();
const sns = new AWS.SNS();

exports.handler = async (event) => {
  // Get the bucket and key from the event
  const sourceBucket = event.Records[0].s3.bucket.name;
  const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
  
  // Skip processing if the file is not an image
  if (!key.match(/\.(jpg|jpeg|png|gif)$/i)) {
    console.log('Not an image file, skipping processing');
    return;
  }
  
  // Get environment variables
  const destinationBucket = process.env.DESTINATION_BUCKET;
  const topicArn = process.env.SNS_TOPIC_ARN;
  const width = parseInt(process.env.RESIZE_WIDTH || 800);
  
  try {
    // Get the image from S3
    const s3Object = await s3.getObject({
      Bucket: sourceBucket,
      Key: key
    }).promise();
    
    // Resize the image
    const resizedImage = await sharp(s3Object.Body)
      .resize(width)
      .toBuffer();
    
    // Upload the resized image to the destination bucket
    await s3.putObject({
      Bucket: destinationBucket,
      Key: key,
      Body: resizedImage,
      ContentType: s3Object.ContentType
    }).promise();
    
    // Send a notification
    await sns.publish({
      TopicArn: topicArn,
      Subject: 'Image Resized Successfully',
      Message: `The image ${key} has been successfully resized and saved to ${destinationBucket}.`
    }).promise();
    
    console.log(`Successfully resized ${key} and uploaded to ${destinationBucket}`);
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Image resized successfully',
        source: sourceBucket,
        destination: destinationBucket,
        key: key
      })
    };
  } catch (error) {
    console.error('Error processing image:', error);
    throw error;
  }
};

provider "aws" {
  region = var.aws_region
}

# S3 Bucket for original images
module "s3_bucket_original" {
  source = "./modules/s3"

  bucket_name         = var.source_bucket_name
  tags                = var.tags
  enable_notification = true
  lambda_function_arn = module.lambda_resize.function_arn
  lambda_permission   = module.lambda_resize.s3_permission
}

# S3 Bucket for resized images
module "s3_bucket_resized" {
  source = "./modules/s3"

  bucket_name = var.destination_bucket_name
  tags        = var.tags
}

# SNS Topic for notifications
module "sns_topic" {
  source = "./modules/sns"

  topic_name       = var.sns_topic_name
  email_addresses  = var.notification_emails
  tags             = var.tags
}

# Lambda function for image resizing
module "lambda_resize" {
  source = "./modules/lambda"

  function_name         = var.lambda_function_name
  lambda_source_file    = "${path.module}/src/resize_image.js"
  handler               = "resize_image.handler"
  runtime               = "nodejs18.x"
  timeout               = 60
  memory_size           = 256
  enable_s3_trigger     = true
  s3_bucket_arn         = module.s3_bucket_original.bucket_arn
  
  environment_variables = {
    DESTINATION_BUCKET = module.s3_bucket_resized.bucket_id
    SNS_TOPIC_ARN      = module.sns_topic.topic_arn
    RESIZE_WIDTH       = var.resize_width
  }

  additional_policy_statements = [
    {
      Action = [
        "s3:GetObject"
      ]
      Effect   = "Allow"
      Resource = "${module.s3_bucket_original.bucket_arn}/*"
    },
    {
      Action = [
        "s3:PutObject"
      ]
      Effect   = "Allow"
      Resource = "${module.s3_bucket_resized.bucket_arn}/*"
    },
    {
      Action = [
        "sns:Publish"
      ]
      Effect   = "Allow"
      Resource = module.sns_topic.topic_arn
    }
  ]

  tags = var.tags
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "source_bucket_name" {
  description = "Name of the S3 bucket for original images"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the S3 bucket for resized images"
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "notification_emails" {
  description = "List of email addresses to receive notifications"
  type        = list(string)
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "resize_width" {
  description = "Width to resize images to (in pixels)"
  type        = number
  default     = 800
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

aws_region             = "us-east-1"
source_bucket_name     = "image-resizing-source-bucket"
destination_bucket_name = "image-resizing-destination-bucket"
sns_topic_name         = "image-resize-notification"
notification_emails    = ["user@example.com"]
lambda_function_name   = "image-resize-function"
resize_width           = 800

tags = {
  Project     = "Image Resizing Service"
  Environment = "Production"
  ManagedBy   = "Terraform"
}

output "source_bucket_name" {
  description = "Name of the source S3 bucket"
  value       = module.s3_bucket_original.bucket_id
}

output "destination_bucket_name" {
  description = "Name of the destination S3 bucket"
  value       = module.s3_bucket_resized.bucket_id
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_resize.function_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.sns_topic.topic_arn
}

# AWS Serverless Image Resizing Solution

This Terraform project creates an automated image resizing solution in AWS using serverless technologies:

- **S3** for storage of original and resized images
- **Lambda** for image processing
- **SNS** for email notifications

## Architecture

1. User uploads an image to the source S3 bucket
2. This triggers a Lambda function that resizes the image
3. The Lambda function saves the resized image to a destination S3 bucket
4. The Lambda function sends a notification via SNS
5. SNS delivers an email notification

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 1.0.0+)
- Node.js and NPM (for local development of Lambda function)

## Setup and Deployment

1. Install the required NPM packages for the Lambda function:

```bash
cd src
npm init -y
npm install aws-sdk sharp --save
```

2. Update `terraform.tfvars` with your specific values:

```hcl
aws_region = "us-east-1"
source_bucket_name = "your-source-bucket-name"
destination_bucket_name = "your-destination-bucket-name"
notification_emails = ["your-email@example.com"]
# ... other variables
```

3. Initialize, plan, and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

## Testing the Solution

1. Upload an image to the source S3 bucket:

```bash
aws s3 cp test-image.jpg s3://your-source-bucket-name/
```

2. Check the destination S3 bucket for the resized image:

```bash
aws s3 ls s3://your-destination-bucket-name/
```

3. Verify you received an email notification.

## Customization

- Modify `src/resize_image.js` to implement different image processing logic
- Update `terraform.tfvars` to change configuration parameters
- Add more subscribers to the SNS topic in `notification_emails` variable

## Cleanup

To remove all resources created by this project:

```bash
terraform destroy
```

## Directory Structure

```
.
├── main.tf               # Root module configuration
├── variables.tf          # Root variable definitions
├── outputs.tf            # Root output definitions
├── terraform.tfvars      # Variable values
├── src/
│   └── resize_image.js   # Lambda function code
└── modules/
    ├── s3/               # S3 bucket module
    ├── lambda/           # Lambda function module
    └── sns/              # SNS topic module
```

{
  "name": "image-resize-lambda",
  "version": "1.0.0",
  "description": "AWS Lambda function for image resizing",
  "main": "resize_image.js",
  "dependencies": {
    "aws-sdk": "^2.1456.0",
    "sharp": "^0.32.6"
  },
  "devDependencies": {},
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC"
}

Based on the diagram, I've created a comprehensive Terraform implementation for an AWS serverless image resizing solution. The architecture consists of:

1. A source S3 bucket where users upload images
2. A Lambda function triggered by new image uploads
3. A destination S3 bucket where resized images are stored
4. An SNS topic that sends email notifications when processing completes

## Project Structure

The implementation uses a modular approach with the following components:

### Modules
- **S3 Module**: Creates S3 buckets with optional event notifications
- **Lambda Module**: Creates Lambda functions with appropriate IAM roles and permissions
- **SNS Module**: Creates SNS topics with email subscriptions

### Root Configuration
- **main.tf**: Orchestrates the modules together
- **variables.tf**: Defines input variables
- **terraform.tfvars**: Sets default values for variables
- **outputs.tf**: Defines output values

### Lambda Function
- **src/resize_image.js**: Contains the Node.js code for image resizing using the Sharp library

### Documentation
- **README.md**: Provides detailed usage instructions

## How it Works

1. When a user uploads an image to the source S3 bucket, it triggers the Lambda function
2. The Lambda function retrieves the image, resizes it using the Sharp library
3. The resized image is saved to the destination S3 bucket
4. The Lambda function sends a notification to the SNS topic
5. The SNS topic delivers an email notification to subscribed email addresses

This implementation follows AWS best practices:
- Uses IAM roles with least privilege permissions
- Properly configures bucket policies to block public access
- Uses environment variables for configuration
- Implements proper error handling in the Lambda function

To deploy this solution, simply update the values in `terraform.tfvars` with your specific configuration and run `terraform apply`.