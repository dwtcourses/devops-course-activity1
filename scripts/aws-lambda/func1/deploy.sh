#!/bin/bash -ex
#
# Install AWS Lambda function: lambda-echo 
#
# created 14-April-2018, steve@blueboxblue.com

## AWS_ACCESS_KEY_ID, and AWS SECRET_ACCESS_KEY are configured using aws configure

## source the variables.sh file, set environment variables as declared within.
source ./variables.sh
echo "BEGIN: Environment variables:"
echo "FUNCTION_NAME=$FUNCTION_NAME"
echo "FIRST_NAME=$FIRST_NAME"
echo "LAST_NAME=$LAST_NAME"

if [ -z $FIRST_NAME ] || [ -z $LAST_NAME ] || [ -z $FUNCTION_NAME ]; then
	echo "ERROR: Required variables have not been set!"
	echo "Please edit variable.sh and enter a FUNCTION_NAME, FIRST_NAME, and LAST_NAME, then try again!"
	echo "Exiting.."
	exit 1
fi
echo "END: Environment variables:"

## Setup

	nodeVersion=nodejs6.10
    lambda_function_name=$FUNCTION_NAME
    lambda_description="Echo Static String Responder"
    lambda_handler=lambda-echo.handler
    lambda_memory=128
    lambda_timeout=2

<<<<<<< HEAD
    lambda_function_file=./lambda-files/function.js
    lambda_assume_role_policy_file=./lambda-files/assume-role-policy.json
=======
    lambda_function_file=./lambda-echo.js
    lambda_assume_role_policy_file=$lambda_function_name-assume-role-policy.json
>>>>>>> 0b39dc81c8b2327f23daf4fd42e59eda3a88375a

## Create ZIP file

    lambda_zip_dir=$(mktemp -d /tmp/$lambda_function_name.XXXXXX)
    lambda_zip_file=$lambda_zip_dir/$lambda_function_name.zip
	#-q (quiet), -r (recursive)
    #zip -q -r $lambda_zip_file $lambda_function_file
	zip -r $lambda_zip_file lamda-files *

## Create Role and attach policies

	
	role_name="lambda-echo-role"
	result=$(aws iam get-role --role-name ${role_name} --output text | grep -i ${role_name})
	echo $result
	if [ $? == 0 ]; then
		echo "[${role_name}], already exists, getting arn.."
		#We need to get the arn
		lambda_role_arn=$(aws iam get-role --role-name ${role_name} --output text --query Role.[Arn])
		echo "$lambda_role_arn=[$lambda_role_arn=]"
		
		
	else
		echo "Creating new IAM Role:[${role_name}]"
		
		 lambda_role_arn=$(aws iam create-role \
     --role-name ${role_name} \
     --assume-role-policy-document "file://$lambda_assume_role_policy_file"\
     --output text \
     --query 'Role.Arn'
    )
		
	fi

	# Seems to be some timing issue here
    sleep 10

## Create/Update the function and upload the ZIP file

	result=$( aws lambda list-functions --output json --query Functions[0].FunctionName )
	echo $result
	if [ "$result" != "null" ]; then
		echo "** In Update section **"
		echo "Lambda Function:[${lambda_function_name}], already exists, updating.."
	    aws lambda update-function-code \
		--function-name "$lambda_function_name" \
		--zip-file "fileb://$lambda_zip_file"
		
	else
		echo "** In Create Section **"
		echo "Lambda Function:[${lambda_function_name}], does not exist, creating.."
		aws lambda create-function \
		--function-name "$lambda_function_name" \
		--environment Variables="{FIRST_NAME=${FIRST_NAME},LAST_NAME=${LAST_NAME}}" \
		--runtime "$nodeVersion" \
		--memory-size "$lambda_memory" \
		--timeout "$lambda_timeout" \
		--role "$lambda_role_arn" \
		--handler "$lambda_handler" \
		--description "$lambda_description" \
		--zip-file "fileb://$lambda_zip_file"
	fi

    

## Cleanup

    rm -r $lambda_zip_dir

exit 0