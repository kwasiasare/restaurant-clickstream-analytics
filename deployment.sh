#!/bin/bash
# CloudFormation Deployment Script for Restaurant Clickstream Analytics Solution
# Usage: ./deploy.sh [create|update|delete]

# Configuration variables
STACK_NAME="restaurant-clickstream-analytics"
TEMPLATE_FILE="clickstream-template.yaml"
REGION="us-east-1"
BUCKET_NAME="clickstream-analytics-$(date +%s)"
LAMBDA_CODE_BUCKET=""  # Leave empty to use inline code
LAMBDA_CODE_KEY=""     # Leave empty to use inline code

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if the template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found."
    exit 1
fi

# Function to wait for a stack operation to complete
wait_for_stack() {
    local stack_name=$1
    local operation=$2
    local status
    
    echo "Waiting for stack $operation to complete..."
    
    while true; do
        status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$REGION" --query "Stacks[0].StackStatus" --output text 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            if [ "$operation" == "DELETE" ]; then
                echo "Stack deletion completed."
                break
            else
                echo "Error checking stack status."
                exit 1
            fi
        fi
        
        case "$status" in
            *_COMPLETE)
                echo "Stack $operation completed with status: $status"
                break
                ;;
            *_FAILED)
                echo "Stack $operation failed with status: $status"
                exit 1
                ;;
            *_IN_PROGRESS)
                echo "Stack $operation in progress: $status"
                sleep 10
                ;;
            *)
                echo "Unknown stack status: $status"
                exit 1
                ;;
        esac
    done
}

# Function to create or update the stack
deploy_stack() {
    local operation=$1
    local cmd="aws cloudformation $operation-stack"
    local params=""
    
    # Build parameters string
    params="$params ParameterKey=BucketName,ParameterValue=$BUCKET_NAME"
    params="$params ParameterKey=DeliveryStreamName,ParameterValue=clickstream-delivery"
    params="$params ParameterKey=LambdaFunctionName,ParameterValue=transform-clickstream-data"
    
    if [ ! -z "$LAMBDA_CODE_BUCKET" ] && [ ! -z "$LAMBDA_CODE_KEY" ]; then
        params="$params ParameterKey=LambdaCodeS3Bucket,ParameterValue=$LAMBDA_CODE_BUCKET"
        params="$params ParameterKey=LambdaCodeS3Key,ParameterValue=$LAMBDA_CODE_KEY"
    fi
    
    # Add additional parameters as needed
    
    # Create or update the stack
    if [ "$operation" == "create" ]; then
        echo "Creating new CloudFormation stack: $STACK_NAME"
        $cmd --stack-name "$STACK_NAME" \
            --template-body file://$TEMPLATE_FILE \
            --capabilities CAPABILITY_IAM \
            --parameters $params \
            --region "$REGION"
    else
        echo "Updating CloudFormation stack: $STACK_NAME"
        $cmd --stack-name "$STACK_NAME" \
            --template-body file://$TEMPLATE_FILE \
            --capabilities CAPABILITY_IAM \
            --parameters $params \
            --region "$REGION"
    fi
    
    if [ $? -eq 0 ]; then
        wait_for_stack "$STACK_NAME" "${operation^^}"
    else
        echo "Failed to $operation stack."
        exit 1
    fi
}

# Function to delete the stack
delete_stack() {
    echo "Deleting CloudFormation stack: $STACK_NAME"
    aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
    
    if [ $? -eq 0 ]; then
        wait_for_stack "$STACK_NAME" "DELETE"
    else
        echo "Failed to delete stack."
        exit 1
    fi
}

# Function to display stack outputs
display_outputs() {
    echo "Stack outputs:"
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query "Stacks[0].Outputs" --output table
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 [create|update|delete]"
    exit 1
fi

case "$1" in
    create)
        deploy_stack "create"
        display_outputs
        ;;
    update)
        deploy_stack "update"
        display_outputs
        ;;
    delete)
        delete_stack
        ;;
    *)
        echo "Invalid operation. Use create, update, or delete."
        exit 1
        ;;
esac

echo "Operation completed successfully!"