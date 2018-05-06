#!/bin/bash
###########################################################################
#
# Script        : deploy.sh
# Purpose       : Deploy a lambda function.
# Authors       : Steve Robinson - http://www.blueboxblue.com steve@blueboxblue.com
# Created       : April 2018 for DevOps course
# 
# History
# date           ver  who  what 
# ----           ---  ---  ----
# 14-April-2018  0.1  scr  First Version
# 19-April-2018  0.2  scr  Updated checks, annd functions for trapping awscli errors
# 20-APril-2018  0.3  scr  Updated Find function, and added output of ARN required for Alexa.
#
VERSION=0.3
## AWS_ACCESS_KEY_ID, and AWS SECRET_ACCESS_KEY are configured using aws configure


##########################################################################
#
# showHelp() - display full help
#
##########################################################################
showHelp() {

    echo "Usage: ${0##*/} -n <Enter function name e.g myfunc1>"
    echo 
    echo "Deploy Lamda Function"
    echo "Options:"
    echo "  -n           Name to use for Lambda Function once deployed."
	echo "  -h           This help message"
    exit 1
    
}
 
##########################################################################
#
# validateArgs() - parameter validation
#
##########################################################################
validateArgs() 
{ 
    
    while getopts ":hn:"  opt; do
        echo "\$opt=$opt$, \$OPTIND=$OPTIND, \$OPTARG=$OPTARG"
        case $opt in
       
        n)  export FUNCTION_NAME="${OPTARG}"
	        ;;
			
		h)  showHelp
            ;;
			
		\?) echo "No option specified"
			;;
 
        *)  echo "Invalid option -${OPTARG}">&2
            showHelp
			exit 0
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

#################################################################
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

echo "FUNCTION_NAME"=$FUNCTION_NAME
if [ -z $FUNCTION_NAME ]; then
	echo "ERROR: Required variables have not been set!"
	echo "Please enter a value for FUNCTION_NAME, then try again!"
	exit 1
fi
echo "END: Environment variables:"


## Setup

	nodeVersion=nodejs6.10
    lambda_function_name=$FUNCTION_NAME
    lambda_description="Echo Static String Responder"
    lambda_handler=$FUNCTION_NAME.handler
    lambda_memory=128
    lambda_timeout=2
    lambda_function_template=./lambda-code.js
	lambda_function_file=./$FUNCTION_NAME.js
	lambda_package_file=./package.json
	lambda_modules_folder=./node_modules
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
	zip -r $lambda_zip_file $lambda_function_file $lambda_package_file $lambda_modules_folder
	
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


## Create/Update the function and upload the ZIP file

ResourceNotFoundException() {
	echo "ERROR TYPE: ResourceNotFoundException"
	echo "ERROR REASON: Lambda function:["${lambda_function_name}"], does not exist"
	echo "Continuing..."
}
CMD="aws lambda list-functions --query ""Functions[?FunctionName=='${FUNCTION_NAME}'].FunctionName"" --output text"
echo "CMD to be executed:"
echo "$CMD"
FUNCTION_EXISTS=$($CMD)
echo "FUNCTION_EXISTS="$FUNCTION_EXISTS

if [ -n "${FUNCTION_EXISTS}" ]; then
	echo "** In Delete Section **"
	echo "Lambda Function:[${FUNCTION_NAME}], already exists, deleting.."
	$(aws lambda delete-function --function-name ${FUNCTION_NAME}) || ResourceNotFoundException
	echo "Delete action issued, now checking status."
	while [ -n $FUNCTION_EXISTS ]; do
		echo "Checking deleted state?"
		echo "tick...tock..."
		CMD="aws lambda list-functions --query ""Functions[?FunctionName=='${FUNCTION_NAME}'].FunctionName"" --output text"
		echo "CMD to be executed:"
		echo "$CMD"
		FUNCTION_EXISTS=$($CMD)
		echo "FUNCTION_EXISTS="$FUNCTION_EXISTS
		if [ -z $FUNCTION_EXISTS ]; then
			break
		fi
	done
fi
	
echo "Creating Lambda Function:[${lambda_function_name}]"
aws lambda create-function \
--function-name "$lambda_function_name" \
--runtime "$nodeVersion" \
--memory-size "$lambda_memory" \
--timeout "$lambda_timeout" \
--role "$lambda_role_arn" \
--handler "$lambda_handler" \
--description "$lambda_description" \
--zip-file "fileb://$lambda_zip_file"


echo "Getting ARN"
CMD="aws lambda list-functions --query ""Functions[?FunctionName=='${FUNCTION_NAME}'].FunctionArn"" --output text"
echo "CMD to be executed:"
echo "$CMD"
ARN=$($CMD)
echo "FunctionArn:[$ARN]"


### Cleanup
echo "Cleaning up temp files..."
rm -r $lambda_zip_dir
echo "Cleanup complete."

exit 0