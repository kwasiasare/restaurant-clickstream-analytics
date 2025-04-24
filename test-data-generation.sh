#!/bin/bash
# Test Data Generation Script for Restaurant Clickstream Analytics
# Usage: ./generate-test-data.sh <api_endpoint> <api_key>

# Check if required parameters are provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <api_endpoint> [api_key]"
    exit 1
fi

API_ENDPOINT=$1
API_KEY=$2
HEADERS=""

# Set up API key if provided
if [ ! -z "$API_KEY" ]; then
    HEADERS="-H x-api-key:$API_KEY"
fi

# Function to send data to API Gateway
send_data() {
    local element=$1
    local time_spent=$2
    
    # Create JSON payload
    JSON_DATA="{\"element_clicked\":\"$element\",\"time_spent\":$time_spent,\"source_menu\":\"restaurant_name\",\"created_at\":\"$(date -u +"%Y-%m-%d %H:%M:%S")\"}"
    
    echo "Sending data: $JSON_DATA"
    
    # Send request to API Gateway
    response=$(curl -s -X POST \
        $HEADERS \
        -H "Content-Type: application/json" \
        -d "$JSON_DATA" \
        $API_ENDPOINT)
    
    # Check response
    echo "Response: $response"
    echo ""
}

echo "Generating test data for restaurant clickstream analytics..."

# Test data for different menu categories
MENU_ITEMS=(
    "entree_1:45"
    "entree_2:67"
    "entree_3:25"
    "entree_4:32"
    "appetizer_1:18"
    "appetizer_2:22"
    "dessert_1:30"
    "dessert_2:28"
    "drink_1:10"
    "drink_2:8"
    "drink_3:14"
    "drink_4:12"
    "special_1:55"
    "special_2:40"
)

# Send multiple data points
echo "Sending test data points..."
for item in "${MENU_ITEMS[@]}"; do
    element=$(echo $item | cut -d':' -f1)
    time_spent=$(echo $item | cut -d':' -f2)
    
    # Send each item 1-3 times with varying time_spent
    count=$((1 + RANDOM % 3))
    for (( i=1; i<=count; i++ )); do
        # Vary the time spent slightly
        variation=$((RANDOM % 10 - 5))
        actual_time=$((time_spent + variation))
        if [ $actual_time -lt 1 ]; then actual_time=1; fi
        
        send_data "$element" $actual_time
        
        # Add random delay between requests
        sleep 0.$(( RANDOM % 9 + 1 ))
    done
done

echo "Generated $(( ${#MENU_ITEMS[@]} * 2 )) test data points."
echo "Test data generation complete!"