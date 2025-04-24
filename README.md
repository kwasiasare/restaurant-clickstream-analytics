Deployment Guide for Restaurant Clickstream Analytics
This guide walks you through the process of deploying and testing the Restaurant Clickstream Analytics solution using AWS CloudFormation.
Prerequisites
Before you begin, make sure you have:

An AWS account with appropriate permissions
AWS CLI installed and configured (version 2.x recommended)
Basic familiarity with AWS services and CloudFormation
Bash shell environment (Linux, macOS, or Windows with WSL)

Deployment Steps
1. Prepare the Template
Save the CloudFormation template to a file named clickstream-template.yaml.
2. Validate the Template
Before deploying, validate the template to ensure it's correctly formatted and contains no errors:
bash./validate.sh clickstream-template.yaml
This script will check the template for syntax errors, best practices, and potential security issues.
3. Deploy the Stack
Use the deployment script to create the CloudFormation stack:
bash./deploy.sh create
The script will:

Create a unique S3 bucket name
Deploy all resources defined in the template
Wait for the deployment to complete
Display the outputs (including API endpoint)

The deployment typically takes 5-10 minutes to complete.
4. Test the Deployment
Once deployed, you can test the solution by sending sample clickstream data using the test data generation script:
bash# Get the API endpoint from the stack outputs
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='APIEndpoint'].OutputValue" --output text)

# Get the API key from the stack outputs
API_KEY=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='APIKeyId'].OutputValue" --output text)
API_KEY_VALUE=$(aws apigateway get-api-key --api-key $API_KEY --include-value --query "value" --output text)

# Generate test data
./generate-test-data.sh $API_ENDPOINT $API_KEY_VALUE
5. Verify Data Flow
After sending test data, verify that the data is flowing through the system:

Check S3 Bucket:
bash# Get the S3 bucket name
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text)

# List objects in the bucket
aws s3 ls s3://$BUCKET_NAME/ --recursive

Run the Glue Crawler manually (if needed):
bash# Get the crawler name
CRAWLER_NAME=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='GlueCrawlerName'].OutputValue" --output text)

# Start the crawler
aws glue start-crawler --name $CRAWLER_NAME

Query the data with Athena:
bash# Get the database name
DATABASE_NAME=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='GlueDatabaseName'].OutputValue" --output text)

# Execute a sample query (note: this requires the AWS CLI v2)
aws athena start-query-execution \
  --query-string "SELECT * FROM \"$DATABASE_NAME\".clickstream_* LIMIT 10;" \
  --query-execution-context "Database=$DATABASE_NAME" \
  --result-configuration "OutputLocation=s3://$BUCKET_NAME/athena-results/"


6. Set Up QuickSight
To visualize the data:

Log in to the AWS Management Console and navigate to QuickSight
If you're a new user, sign up for QuickSight Enterprise edition
In QuickSight, configure access to the S3 bucket and Athena
Create a new dataset using Athena as the source
Choose the database and table created by the Glue Crawler
Create visualizations to analyze menu item popularity

7. Update the Stack (if needed)
If you need to make changes to the deployment:
bash# Edit the template file as needed
# Then update the stack
./deploy.sh update
8. Clean Up
When you're done with the solution, you can remove all resources:
bash./deploy.sh delete
Note: The S3 bucket won't be automatically deleted due to the DeletionPolicy: Retain setting. To completely remove all resources, manually empty and delete the S3 bucket:
bashBUCKET_NAME=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text)
aws s3 rm s3://$BUCKET_NAME/ --recursive
aws s3api delete-bucket --bucket $BUCKET_NAME
Troubleshooting
Common Issues

Stack Creation Fails: Check the CloudFormation events for detailed error messages:
bashaws cloudformation describe-stack-events --stack-name restaurant-clickstream-analytics

No Data in S3: Verify the API Gateway configuration and Lambda function:
bash# Get function name
FUNCTION_NAME=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionName'].OutputValue" --output text)

# Check CloudWatch logs
aws logs describe-log-streams --log-group-name /aws/lambda/$FUNCTION_NAME

Athena Query Fails: Verify the Glue Crawler has successfully created the table:
bash# Get database name
DATABASE_NAME=$(aws cloudformation describe-stacks --stack-name restaurant-clickstream-analytics --query "Stacks[0].Outputs[?OutputKey=='GlueDatabaseName'].OutputValue" --output text)

# List tables
aws glue get-tables --database-name $DATABASE_NAME


Next Steps
After successful deployment and testing, consider these enhancements:

Implement additional security measures like VPC endpoints
Set up CloudWatch alarms for monitoring
Add more complex data transformation in the Lambda function
Create automated reports using QuickSight
Implement user authentication for the API Gateway

Support
For issues or questions about this deployment, contact your AWS support team or consult the AWS documentation for the individual services.# restaurant-clickstream-analytics