#!/bin/bash -ex
# -ex (debug variables)
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

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

## Setup

	nodeVersion=nodejs6.10
    lambda_function_name=$FUNCTION_NAME
    lambda_description="Echo Static String Responder"
    lambda_handler=$FUNCTION_NAME.handler
    lambda_memory=128
    lambda_timeout=2
    lambda_function_template=./lambda-code.js
	lambda_function_file=./$FUNCTION_NAME.js
	lambda_policy_template=./assume-role-policy.json
	lambda_assume_role_policy_file=./$FUNCTION_NAME-assume-role-policy.json
	
	
	## We copy the lambda-code.js file that has the node code, and re-name it to the dynamic function name
	## From testing, it looks like, Lamda like the <lambda_file>.js to be the same name as the actual function name.
	cp $lambda_function_template ./$lambda_function_file
	cp $lambda_policy_template ./$lambda_assume_role_policy_file
	role_name="${FUNCTION_NAME}-role"


## Create ZIP file
	echo "Creating temp directory"
	cmd="mktemp -d /tmp/$lambda_function_name.XXXXXX"
	echo "EXECUTING cmd="$cmd
	lambda_zip_dir=$($cmd)
	echo "lambda_zip_dir="$lambda_zip_dir
	ls $lambda_zip_dir

	echo "Creating a zip file"
	lambda_zip_file=$lambda_zip_dir/$lambda_function_name.zip
	echo "lambda_zip_file="$lambda_zip_file
  	#-q (quiet), -r (recursive), -j (no root folder)
	zip -r $lambda_zip_file $lambda_function_file
	ls $lambda_zip_file

## Create Role and attach policies
	IAM_ROLE=$(aws iam get-role --role-name ${role_name} --output text | grep -i ${role_name}) || true
	echo $IAM_ROLE
	if [ -z "$IAM_ROLE" ]; then
	
	echo "Creating new IAM Role:[${role_name}]"
		
		 lambda_role_arn=$(aws iam create-role \
     --role-name ${role_name} \
     --assume-role-policy-document "file://$lambda_assume_role_policy_file"\
     --output text \
     --query 'Role.Arn'
    )
	
		
	else
		echo "[${role_name}], already exists, getting arn.."
		#We need to get the arn
		lambda_role_arn=$(aws iam get-role --role-name ${role_name} --output text --query Role.[Arn])
		echo "$lambda_role_arn=[$lambda_role_arn=]"
		
		
	fi

	# Seems to be some timing issue here
    sleep 10

## Create/Update the function and upload the ZIP file

	result=$( aws lambda list-functions --output json --query Functions[0].FunctionName )
	echo $result
	if [ "$result" != "null" ]; then
		echo "** In Update section **"
		echo "Lambda Function:[${lambda_function_name}], already exists, deleting.."
		aws lambda delete-function --function-name ${lambda_function_name}
		
	fi
	
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

## Cleanup

    rm -r $lambda_zip_dir

exit 0