#!/bin/bash -ex
# Install AWS Gateway API for AWS Lambda function
#
# created 15-April-2018, steve@blueboxblue.com

## AWS_ACCESS_KEY_ID, and AWS SECRET_ACCESS_KEY are configured using aws configure

## Setup
API_NAME="echo-instructor"
LAMBDA_NAME="myfunc5"
LAMBDA_ARN="arn:aws:lambda:eu-west-1:948957106729:function:$LAMBDA_NAME"
REGION="eu-west-1"
HTTP_METHOD="GET"
STAGE_NAME="Prod"
STATUS_CODE=200



##This script creats and API Gateway
##I would rather use CloudFormation, but this is easier to understand for a classrom


API_ID=$(aws apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" \
--output text --region ${REGION})

echo "API_ID=[$API_ID]"

if [ -z "$API_ID" ]; then
	echo "Creating new API:[${API_NAME}]"
	##Create the gateway and collect some details about it for later use.
	echo "create-rest-api"
	aws apigateway create-rest-api --name "${API_NAME}" \
	--description "Api for ${LAMBDA_NAME}" \
	--region ${REGION}
	
else
	echo "[${API_NAME}], already exists, skipping creation"
fi


##Get the API ID
API_ID=$(aws apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" \
--output text --region ${REGION})
echo "API_ID=[$API_ID]"

PARENT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id ${API_ID} \
--query 'items[?path].id' --output text --region ${REGION})
echo "PARENT_RESOURCE_ID=[$PARENT_RESOURCE_ID]"
if [ -z "$PARENT_RESOURCE_ID" ]; then
	echo "Error with PARENT_RESOURCE_ID, it is null"
	exit 1
fi


##Before adding the resource, we need to supply both the API ID as well as the parent resource ID. 
##Note: These IDs are completely different from any other AWS IDs.

echo "Getting Resource Id"
#?AvailabilityZone==`us-west-2a
RESOURCE_ID=$(aws apigateway get-resources --rest-api-id ${API_ID} \
--query 'items[?path==`/igor`].id' --output text --region ${REGION})
echo "RESOURCE_ID=[$RESOURCE_ID]"

if [ -z "$RESOURCE_ID" ]; then
	echo "Creating resource using..."
	echo "PARENT_RESOURCE_ID= {PARENT_RESOURCE_ID}]"
	echo "API_ID= {API_ID}]"
	
	echo "create-resource"
	aws apigateway create-resource --rest-api-id ${API_ID} \
	--parent-id ${PARENT_RESOURCE_ID} \
	--path-part igor \
	--region ${REGION}
	
else
	echo "Resource path-part=[igor], Already exists!"
fi

## Next up is the GET method and as we don’t want authorization at this time,  
## we set the authorization-type to NONE.

##Check if method exists
##get-method
##--rest-api-id <value>
##--resource-id <value>
##--http-method <value>

put-method-func() {
echo "Adding put-method for ${HTTP_METHOD}"
	aws apigateway put-method --rest-api-id ${API_ID} \
	--resource-id ${RESOURCE_ID} \
	--http-method ${HTTP_METHOD} \
	--authorization-type NONE \
	--region ${REGION}
	
}

METHOD=$(aws apigateway get-method --rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} --query 'httpMethod==`GET`' || put-method-func "Error")
echo "METHOD="${METHOD}


##Adding the integration is a long command, split out over multiple lines 
## to improve readability. We supply all the details concerning the method we want to attach this to, 
## then we can hook/connect it up to our Lambda function by calling a very long URI. 
## This URI is an ARN that contains another ARN.
##--uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:HelloWorld/invocations
URI=arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations
echo "$URI=[$URI]"

echo "put-integration"
aws apigateway put-integration --rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} \
--type AWS \
--integration-http-method POST \
--uri $URI \
--region ${REGION}

##--request-templates '{"application/x-www-form-urlencoded":"{\"body\": $input.json(\"$\")}"}'



## Next is the response translations. In fact, we don’t need any translations. 
## That means we provide an empty model for the method response and a complete pass through for the integration response. 
## Again, the actual commands for this are a lot longer. 
## Even though these are so simple, they are required though.

#get-method-response
#--rest-api-id <value>
#--resource-id <value>
#--http-method <value>
#--status-code <value>

get-method-response-func() {
	echo "Adding put-method-response for ${HTTP_METHOD}"
	aws apigateway put-method-response \
	--rest-api-id ${API_ID} \
	--resource-id ${RESOURCE_ID} \
	--http-method ${HTTP_METHOD} \
	--status-code ${STATUS_CODE} \
	--response-models "{}" \
	--region ${REGION}
}


METHOD_RESPONSE=$(aws apigateway get-method-response --rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} \
--status-code ${STATUS_CODE} \
--query 'httpMethod==`${HTTP_METHOD}`' || get-method-response-func "Error")
echo "METHOD_RESPONSE="${METHOD_RESPONSE}


echo "put-integration-response"
aws apigateway put-integration-response \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} \
--status-code ${STATUS_CODE} \
--selection-pattern ".*" \
--region ${REGION}


## And finally the gateway is now configured. 
## At least, a version of it is configured as we still need to deploy it. 
## That luckily though is quite simple again
echo "create-deployment"
aws apigateway create-deployment \
--rest-api-id ${API_ID} \
--stage-name ${STAGE_NAME} \
--region ${REGION}


## Making the two work together
## At this point we have a Lambda function and an API Gateway.
## Now ,we authorize the Gateway to execute the Lambda function.
## To do this, we set up two permissions. 
## 1.  Allow test command from either the command line or the test function in the Console.
## 2.  Allow actual production environment used for external calls.

#get the api-arn and concat further information
echo "Geting API QW ARN"
API_ARN=$(echo ${LAMBDA_ARN} | sed -e 's/lambda/execute-api/' -e "s/function:${LAMBDA_NAME}/${API_ID}/")
echo "API_ARN=[$API_ARN]"


## get-policy
##--function-name <value>

## remove-permission
## --function-name <value>
##--statement-id <value>
##, Get policy (aka get permission), if exist, then delete the permission, and create it, esle create it.

remove-permission-func() {

	echo "ERROR: ResourceNotFoundException"
	echo "Permission did not exist, creating..."
	## Add permission to invoke
	RESULT=$(aws lambda add-permission \
	--function-name ${LAMBDA_NAME} \
	--statement-id apigateway-igor-test-1 \
	--action lambda:InvokeFunction \
	--principal apigateway.amazonaws.com \
	--source-arn "${API_ARN}/*/${HTTP_METHOD}/igor" \
	--region ${REGION}  || true)

	echo "return_code="$?
	echo "RESULT="$RESULT

}

DELETED=$(aws lambda remove-permission \
	--function-name ${LAMBDA_NAME} \
	--statement-id apigateway-igor-test-1 || remove-permission-func "Error")


## Add permission to execute [prod] API

echo "The url you have to use in your integration/application settings is:"
echo "https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod/igor"