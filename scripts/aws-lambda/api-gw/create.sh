#!/bin/bash
###########################################################################
#
# Script        : delete.sh
# Purpose       : Install AWS Gateway API for AWS Lambda function
# Authors       : Steve Robinson - http://www.blueboxblue.com steve@blueboxblue.com
# Created       : April 2018 for DevOps course
# 
# History
# date           ver  who  what 
# ----           ---  ---  ----
# 15-April-2018  0.1  scr  Created initial script with hard-codes params
# 20-April-2018  0.2  scr  Added command-line params/switches to pass in Lambda function name
# 01-May-2018    0.3  scr  Added msgb, msge for quick debugger formatting, fixed all conditional tests for existing/nonexisting resources
#
VERSION=0.3
##########################################################################
#
# showHelp() - display full help
#
##########################################################################
showHelp() {

    echo "Usage: ${0##*/} -n <Enter API Gateway Name e.g myapiqw1> -f <Enter Lambda function name e.g myfunc1> -p <Enter partial path e.g mypath1>"
    echo 
    echo "Creating an API Gateway"
    echo "Options:"
    echo "  -n <required>       Name of new API Gateway"
	echo "  -f <required>       Name of existing Lambda function"
	echo "  -p <required>       api partial path"
	echo "  -h                  This help message"
    exit 1
    
}
 
##########################################################################
#
# validateArgs() - parameter validation
#
##########################################################################
validateArgs() 
{ 
    
    while getopts ":h:n:f:p:"  opt; do
        echo "\$opt=$opt$, \$OPTIND=$OPTIND, \$OPTARG=$OPTARG"
        case $opt in
       
        n)  export API_NAME="${OPTARG}"
	        ;;
			
		f)  export LAMBDA_NAME="${OPTARG}"
	        ;;
			
		p)  export PARTIAL_PATH="${OPTARG}"
	        ;;
			
		h)  showHelp
            ;;
			
		\?) echo "Invalid option(s supplied: -$OPTARG" >&2
			showHelp
			exit 1
			;;
			
		:) echo "Option -$OPTARG requires an argument." >&2
			showHelp
			exit 1
			;;
 
        *)  echo "Invalid option -${OPTARG}">&2
            showHelp
			exit 1
            ;;
 
		esac
    done
 
    shift $((OPTIND - 1))
 
    if [ $# -ne 0 ]
    then
        showHelp
		exit 1
    fi
 
}

##########################################################################
#
# msgb() - Print BEGIN <Message>
#
##########################################################################
msgb() {
 str=$1
 symbol=$2
 #num=$2
 let num=${#1}+7
 v=$(printf "%-${num}s" "$symbol")
 echo "${v// /*}"
 echo "BEGIN: "$1
 echo "${v// /*}"
}

##########################################################################
#
# msgb() - Print END <Message>
#
##########################################################################
msge() {
 str=$1
 symbol=$2
 #num=$2
 let num=${#1}+5
 v=$(printf "%-${num}s" "$symbol")
 echo "${v// /*}"
 echo "END: "$1
 echo "${v// /*}"
}

############################################################
# MAIN ENTRY POINT
################################################################
TODAY=$(date +"%d%B%Y")
DATE_FORMAT="+%d/%B/%Y %T"
THIS_SCRIPT=${0##*/}
THIS_SCRIPT=$(basename $THIS_SCRIPT .sh)
validateArgs "$@"


if [ $# -eq 0 ]
	then
		echo "ERROR: No option/switches supplied to function!"
		showHelp
		exit 1
	fi
	
echo "API_NAME=${API_NAME}"
echo "LAMBDA_NAME=${LAMBDA_NAME}"
echo "PARTIAL_PATH=${PARTIAL_PATH}"


## Fixed Variable Setup
REGION="eu-west-1"
HTTP_METHOD="GET"
STAGE_NAME="Prod"
STATUS_CODE=200

##Get the list of functions
#CMD="aws lambda list-functions --output json --query Functions[*].FunctionName"
#echo "CMD="$CMD
#LAMBDA_LIST=$($CMD)
#echo "LAMBDA_LIST=${LAMBDA_LIST}"

## Use awk to trim leading and trailing whitespace
#LAMBDA_LIST=$( echo "${LAMBDA_LIST}"| sed -e 's/^ *//' -e 's/ *$//' );
#echo "*new* LAMBDA_LIST=${LAMBDA_LIST}"

msgb "lambda-exists-func" "*"
lambda-exists() {
	local LOCAL_RESULT=$(aws lambda get-function --function-name ${LAMBDA_NAME} --query Configuration.FunctionName --output text || true)
	#echo "return_code="$?
	#echo "LOCAL_RESULT="$LOCAL_RESULT
	echo $LOCAL_RESULT
}

RESULT=$(lambda-exists)
echo "RESULT="$RESULT
echo "LAMBDA_NAME=${LAMBDA_NAME}"
msge "lambda-exists-func" "*"

if [ "${RESULT}" == "${LAMBDA_NAME}" ]; then
	echo "Lambda function [$LAMBDA_NAME] exists"
	echo "Gettting ARN.."
	msgb "get-function" "*"
	LAMBDA_ARN=$(aws lambda get-function --function-name ${LAMBDA_NAME} --query Configuration.FunctionArn --output text || true)
	echo "LAMBDA_ARN="$LAMBDA_ARN
else
	echo "Lambda function [$LAMBDA_NAME] does not exist! Exiting.."
	exit 1
fi
msge "get-function" "*"
	
msgb "get-rest-apis" "*"
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${API_NAME}'].id" \
--output text --region ${REGION})
msge "get-rest-apis" "*"

echo "API_ID=[$API_ID]"

if [ -z "$API_ID" ]; then
	echo "Creating new API:[${API_NAME}]"
	##Create the gateway and collect some details about it for later use.
	msgb "create-rest-api" "*"
	aws apigateway create-rest-api --name "${API_NAME}" \
	--description "Api for ${LAMBDA_NAME}" \
	--region ${REGION}
	
else
	echo "[${API_NAME}], already exists, skipping creation"
fi
msge "create-rest-api" "*"


##Get the API ID
msgb "get-rest-apis" "*"
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='${API_NAME}'].id" \
--output text --region ${REGION})
echo "API_ID=[$API_ID]"
msge "get-rest-apis " "*"

##Get the Parent Resource ID
msgb "get-resources" "*"
PARENT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id ${API_ID} \
--query 'items[?path].id' --output text --region ${REGION})
echo "PARENT_RESOURCE_ID=[$PARENT_RESOURCE_ID]"
if [ -z "$PARENT_RESOURCE_ID" ]; then
	echo "Error with PARENT_RESOURCE_ID, it is null"
	exit 1
fi
msge "get-resources" "*"

##Before adding the resource, we need to supply both the API ID as well as the parent resource ID. 
##Note: These IDs are completely different from any other AWS IDs.

echo "Getting Resource Id"
#?AvailabilityZone==`us-west-2a
##RESOURCE_ID=$(aws apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/igor`].id' --output text --region ${REGION})
##aws apigateway get-resources --rest-api-id pjij2tiaha --query "items[?path=='/1'].id" --output text --region eu-west-1
## aws apigateway get-resources --rest-api-id pjij2tiaha --query 'items[?path==`/igor`].id' --output text --region eu-west-1
CMD="aws apigateway get-resources --rest-api-id ${API_ID} --query ""items[?path=='/${PARTIAL_PATH}'].id"" --output text --region ${REGION}"
echo "CMD="$CMD
RESOURCE_ID=$( $CMD )
echo "RESOURCE_ID=[$RESOURCE_ID]"


if [ -z "${RESOURCE_ID}" ]; then

	echo "Creating resource using..."
	echo "PARENT_RESOURCE_ID=]${PARENT_RESOURCE_ID}]"
	echo "API_ID=[${API_ID}]"

	msgb "create-resource" "*"
	
	#aws apigateway create-resource --rest-api-id ${API_ID} \
	#--parent-id ${PARENT_RESOURCE_ID} \
	#--path-part ${PARTIAL_PATH} \
	#--region ${REGION}
		
	CMD="aws apigateway create-resource --rest-api-id ${API_ID} --parent-id ${PARENT_RESOURCE_ID} --path-part ${PARTIAL_PATH} --region ${REGION}"
	echo "CMD="$CMD
	RESULT=$($CMD)
	CMD="aws apigateway get-resources --rest-api-id ${API_ID} --query ""items[?path=='/${PARTIAL_PATH}'].id"" --output text --region ${REGION}"
	echo "CMD="$CMD
	RESOURCE_ID=$($CMD)
	echo "RESOURCE_ID=[$RESOURCE_ID]"
else
	echo "Resource path-part=[${PARTIAL_PATH}], Already exists!"
fi
msge "create-resource" "*"

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

msgb "get-method" "*"
METHOD=$(aws apigateway get-method --rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} --query 'httpMethod==`GET`' || put-method-func "Error")
echo "METHOD="${METHOD}
msge "get-method" "*"

##Adding the integration is a long command, split out over multiple lines 
## to improve readability. We supply all the details concerning the method we want to attach this to, 
## then we can hook/connect it up to our Lambda function by calling a very long URI. 
## This URI is an ARN that contains another ARN.
##--uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:HelloWorld/invocations
URI=arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations
echo "$URI=[$URI]"

msgb "put-integration" "*"
aws apigateway put-integration --rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} \
--type AWS \
--integration-http-method POST \
--uri $URI \
--region ${REGION}
##--request-templates '{"application/x-www-form-urlencoded":"{\"body\": $input.json(\"$\")}"}'
msge "put-integration" "*"


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

msgb "get-method-response" "*"
METHOD_RESPONSE=$(aws apigateway get-method-response --rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} \
--status-code ${STATUS_CODE} \
--query 'httpMethod==`${HTTP_METHOD}`' || get-method-response-func "Error")
echo "METHOD_RESPONSE="${METHOD_RESPONSE}
msge "get-method-response" "*"

msgb "put-integration-response" "*"
aws apigateway put-integration-response \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method ${HTTP_METHOD} \
--status-code ${STATUS_CODE} \
--selection-pattern ".*" \
--region ${REGION}
msge "put-integration-response" "*"

## And finally the gateway is now configured. 
## At least, a version of it is configured as we still need to deploy it. 
## That luckily though is quite simple again

msgb "create-deployment" "*"
aws apigateway create-deployment \
--rest-api-id ${API_ID} \
--stage-name ${STAGE_NAME} \
--region ${REGION}
msge "create-deployment" "*"

## Making the two work together
## At this point we have a Lambda function and an API Gateway.
## Now ,we authorize the Gateway to execute the Lambda function.
## To do this, we set up two permissions. 
## 1.  Allow test command from either the command line or the test function in the Console.
## 2.  Allow actual production environment used for external calls.

#Create/Generate the api-arn and concat further information
msgb "generate api-gw arn" "*"
API_ARN=$(echo ${LAMBDA_ARN} | sed -e 's/lambda/execute-api/' -e "s/function:${LAMBDA_NAME}/${API_ID}/")
echo "API_ARN=[$API_ARN]"
msge "generate api-gw arn" "*"

## get-policy
##--function-name <value>

## remove-permission
## --function-name <value>
##--statement-id <value>
##, Get policy (aka get permission), if exist, then delete the permission, and create it, esle create it.

add-permission-func() {

	echo "ERROR: ResourceNotFoundException"
	echo "Permission did not exist, creating..."

	## Add permission to invoke
	RESULT=$(aws lambda add-permission \
	--function-name ${LAMBDA_NAME} \
	--statement-id apigateway-${PARTIAL_PATH}-test-1 \
	--action lambda:InvokeFunction \
	--principal apigateway.amazonaws.com \
	--source-arn "${API_ARN}/*/${HTTP_METHOD}/${PARTIAL_PATH}" \
	--region ${REGION}  || true)

	echo "return_code="$?
	echo "RESULT="$RESULT

}

DELETED=$(aws lambda remove-permission \
	--function-name ${LAMBDA_NAME} \
	--statement-id apigateway-${PARTIAL_PATH}-test-1 || add-permission-func "Error")


## Add permission to execute [prod] API

echo "The url you have to use in your integration/application settings is:"
echo "https://${API_ID}.execute-api.${REGION}.amazonaws.com/$STAGE_NAME/${PARTIAL_PATH}"