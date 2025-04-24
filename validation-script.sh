#!/bin/bash
# CloudFormation Template Validation Script
# Usage: ./validate.sh template.yaml

# Configuration variables
REGION="us-east-1"

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if a template file was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <template_file>"
    exit 1
fi

TEMPLATE_FILE=$1

# Check if the template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found."
    exit 1
fi

echo "Validating CloudFormation template: $TEMPLATE_FILE"

# Validate the template
aws cloudformation validate-template \
    --template-body file://$TEMPLATE_FILE \
    --region "$REGION"

# Check the validation result
if [ $? -eq 0 ]; then
    echo "Template validation successful!"
else
    echo "Template validation failed."
    exit 1
fi

# Estimate the cost of the template (optional)
echo ""
echo "Would you like to estimate the cost of this template? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Getting cost estimate..."
    aws cloudformation estimate-template-cost \
        --template-body file://$TEMPLATE_FILE \
        --region "$REGION"
fi

echo ""
echo "Checking for potential security issues..."
# You would typically use a tool like cfn-nag here
if command -v cfn_nag_scan &> /dev/null; then
    cfn_nag_scan --input-path "$TEMPLATE_FILE"
else
    echo "cfn-nag not installed. Skipping security scan."
    echo "To install: gem install cfn-nag"
fi

echo ""
echo "Checking for best practices..."
# You would typically use a tool like cfn-lint here
if command -v cfn-lint &> /dev/null; then
    cfn-lint "$TEMPLATE_FILE"
else
    echo "cfn-lint not installed. Skipping best practices check."
    echo "To install: pip install cfn-lint"
fi

echo ""
echo "Validation complete!"